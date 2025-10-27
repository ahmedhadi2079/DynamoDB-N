
import os
import sys


import unittest
from unittest.mock import patch, MagicMock

import pandas as pd
import awswrangler as wr
import base64
import json
from datetime import datetime
from datetime import date
from datetime import timezone

sys.path.append(os.path.abspath("../"))
from utils import (
    camel_to_snake_case,
    parse_payload,
    is_unix_timestamp,
    parse_unix_timestamp,
    parse_string_date,
    parse_date,
    apply_schema,
    apply_type_conversions,
    handle_datetime_column,
    write_processed_to_s3,
)
from lambda_function import (
    lambda_handler,
    TABLE_MAPPING
)


def test_camel_to_snake_case():
    assert camel_to_snake_case("CamelCase") == "camel_case"
    assert camel_to_snake_case("camelCase") == "camel_case"
    assert camel_to_snake_case("Already_snake_case") == "already_snake_case"
    assert camel_to_snake_case("NoChange") == "no_change"


def test_parse_payload():
    event = {
        "Records": [
            {
                "kinesis": {
                    "data": base64.b64encode(
                        json.dumps({
                            "dynamodb": {
                                "NewImage": {
                                    "attribute1": {"S": "Value1"},
                                    "attribute2": {"S": "Value2"},
                                    "empty_list": [],  # Should be converted to "null"
                                    "empty_dict": {},  # Should be converted to "null"
                                    "empty_string": ""  # Should be converted to None
                                }
                            }
                        }).encode("utf-8")
                    ).decode("utf-8")
                }
            }
        ]
    }

    df = parse_payload(event)

    # Check transformed column names
    assert "dynamodb_new_image_attribute1_s" in df.columns
    assert "dynamodb_new_image_attribute2_s" in df.columns
    assert "dynamodb_new_image_empty_list" not in df.columns
    assert "dynamodb_new_image_empty_dict" not in df.columns
    assert "dynamodb_new_image_empty_string" in df.columns

    # Check values
    assert df.iloc[0]["dynamodb_new_image_attribute1_s"] == "Value1"
    assert df.iloc[0]["dynamodb_new_image_attribute2_s"] == "Value2"
    assert df.iloc[0]["dynamodb_new_image_empty_string"] is None

    assert "date" in df.columns
    assert df.iloc[0]["date"] == date.today().strftime("%Y-%m-%d")

    assert "timestamp_extracted" in df.columns
    assert isinstance(df.iloc[0]["timestamp_extracted"], datetime)
    assert df.iloc[0]["timestamp_extracted"].tzinfo == timezone.utc

def test_is_unix_timestamp():
    assert is_unix_timestamp(1627765200)  # Unix timestamp in seconds
    assert is_unix_timestamp(1627765200000)  # Unix timestamp in milliseconds
    assert is_unix_timestamp("1627765200")
    assert not is_unix_timestamp("invalid")
    assert not is_unix_timestamp(None)


def test_parse_unix_timestamp():
    assert parse_unix_timestamp(1627765200) == pd.Timestamp("2021-07-31T21:00:00Z")
    assert parse_unix_timestamp(1627765200000) == pd.Timestamp("2021-07-31T21:00:00Z")


def test_parse_string_date():
    # Valid date formats
    assert parse_string_date("2024-07-30T18:27:00Z") == pd.Timestamp("2024-07-30T18:27:00Z")
    assert parse_string_date("7/30/2024 6:27:00 PM") == pd.Timestamp("2024-07-30T18:27:00Z")
    assert parse_string_date("2024-07-30 18:27:00") == pd.Timestamp("2024-07-30T18:27:00Z")
    assert parse_string_date("30-07-2024 18:27:00") == pd.Timestamp("2024-07-30T18:27:00Z")

    # Edge cases
    assert parse_string_date("July 30, 2024 18:27:00") == pd.Timestamp("2024-07-30T18:27:00Z")
    assert parse_string_date("30th July 2024 18:27:00") == pd.Timestamp("2024-07-30T18:27:00Z")
    assert parse_string_date("2024/07/30 18:27:00") == pd.Timestamp("2024-07-30T18:27:00Z")

    # Invalid dates
    assert pd.isna(parse_string_date("invalid-date"))
    assert pd.isna(parse_string_date(None))
    assert pd.isna(parse_string_date(""))
    assert pd.isna(parse_string_date("2024-02-30 10:00:00"))  # Invalid day

    # Time zone handling
    assert parse_string_date("2024-07-30T18:27:00+02:00") == pd.Timestamp("2024-07-30T16:27:00Z")


def test_parse_date():
    assert parse_date(1627765200) == pd.Timestamp("2021-07-31T21:00:00Z")
    assert parse_date("2024-07-30T18:27:00Z") == pd.Timestamp("2024-07-30T18:27:00Z")
    assert pd.isna(parse_date("invalid"))
    assert pd.isna(parse_date(None))


def test_apply_schema():
    df = pd.DataFrame({
        'id': [1, 2, 3],
        'name': ['Alice', 'Bob', 'Charlie'],
        'age': [25, 30, 35],
        'salary': [50000.0, 60000.0, 70000.0],
        'is_active': [True, False, True],
        'created_at': [1633072800, 1633159200, 1633245600]
    })

    schema = {
        'id': 'int',
        'name': 'string',
        'age': 'int',
        'salary': 'double',
        'is_active': 'boolean',
        'created_at': 'timestamp'
    }

    print("Before conversion - created_at dtype:", df['created_at'].dtype)

    result_df = apply_schema(df, schema)

    print("After conversion - created_at dtype:", result_df['created_at'].dtype)
    print("After conversion - created_at values:", result_df['created_at'])

    assert result_df['id'].dtype == 'int32'
    assert result_df['name'].dtype == 'string[python]'
    assert result_df['age'].dtype == 'int32'
    assert result_df['salary'].dtype == 'float64'
    assert result_df['is_active'].dtype == 'bool'
    assert result_df['created_at'].dtype == 'datetime64[ns, UTC]'

    df = pd.DataFrame({
        'id': [1, 2, 3],
        'name': ['Alice', 'Bob', 'Charlie']
    })

    schema = {
        'id': 'int',
        'name': 'string',
        'date': 'date',
        'timestamp_extracted': 'timestamp'
    }

    result_df = apply_schema(df, schema)


def test_apply_type_conversions():
    df = pd.DataFrame({
        'id': [1, 2, 3],
        'name': ['Alice', 'Bob', 'Charlie'],
        'age': [25, 30, 35],
        'salary': [50000.0, 60000.0, 70000.0],
        'is_active': [True, False, True],
        'created_at': [1633072800, 1633159200, 1633245600]
    })

    schema = {
        'id': 'int',
        'name': 'string',
        'age': 'int',
        'salary': 'double',
        'is_active': 'boolean',
        'created_at': 'timestamp'
    }

    schema_type_mapping = {
        "int": "int32",
        "bigint": "int64",
        "string": "string[python]",
        "timestamp": "datetime64[ns]",
        "double": "float64",
        "boolean": "bool",
        "date": "datetime64[ns]",
    }

    result_df = apply_type_conversions(df, schema, schema_type_mapping)

    assert result_df['id'].dtype == 'int32'
    assert result_df['name'].dtype == 'string[python]'
    assert result_df['age'].dtype == 'int32'
    assert result_df['salary'].dtype == 'float64'
    assert result_df['is_active'].dtype == 'bool'
    assert result_df['created_at'].dtype == 'datetime64[ns, UTC]'

    df = pd.DataFrame({
        'id': [1, 2, 3],
        'name': ['Alice', 'Bob', 'Charlie']
    })

    schema = {
        'id': 'int',
        'name': 'string',
        'age': 'int'
    }

    result_df = apply_type_conversions(df, schema, schema_type_mapping)

    assert result_df['id'].dtype == 'int32'
    assert result_df['name'].dtype == 'string[python]'
    assert 'age' not in result_df.columns


def test_numeric_timestamps_seconds():
    """Test conversion of numeric timestamps in seconds"""
    series = pd.Series([1633072800, 1633159200, 1633245600])  # Unix timestamps in seconds
    result_series = handle_datetime_column(series)

    expected = pd.to_datetime(series, unit="s", utc=True)
    pd.testing.assert_series_equal(result_series, expected)

def test_numeric_timestamps_milliseconds():
    """Test conversion of numeric timestamps in milliseconds"""
    series = pd.Series([1633072800000, 1633159200000, 1633245600000])  # Unix timestamps in ms
    result_series = handle_datetime_column(series)

    expected = pd.to_datetime(series, unit="ms", utc=True)
    pd.testing.assert_series_equal(result_series, expected)


def test_already_datetime_column():
    """Test that already datetime columns are returned unchanged"""
    series = pd.to_datetime(['2021-10-01', '2021-10-02', '2021-10-03'], utc=True)
    series = pd.Series(series)

    result_series = handle_datetime_column(series)

    pd.testing.assert_series_equal(result_series, series, check_freq=False) 


@patch.dict(os.environ, {"S3_RAW": "test-bucket"}, clear=True)
@patch("utils.wr.s3.to_parquet")
@patch("utils.data_catalog", autospec=True)
def test_write_to_s3(mock_data_catalog, mock_to_parquet):
    mock_df = pd.DataFrame({"col1": [1, 2], "date": ["2023-01-01", "2023-01-02"]})
    athena_table = "test_table"

    mock_data_catalog.schemas = {athena_table: {"col1": "bigint", "date": "string"}}
    mock_data_catalog.column_comments = {athena_table: {"col1": "Column 1", "date": "Date"}}

    mock_result = {"paths": ["s3://test-bucket/test_table/part1.parquet"]}
    mock_to_parquet.return_value = mock_result

    result = write_processed_to_s3(mock_df, athena_table)

    mock_to_parquet.assert_called_once_with(
        df=mock_df,
        path="s3://test-bucket/test_table/",
        index=False,
        dataset=True,
        database="datalake_raw",
        table=athena_table,
        mode="append",
        compression="snappy",
        schema_evolution="true",
        partition_cols=["date"],
        dtype={"col1": "bigint", "date": "string"},
        glue_table_settings=wr.typing.GlueTableSettings(
            columns_comments={"col1": "Column 1", "date": "Date"}
        ),
    )

    assert result == mock_result


def test_lambda_handler_success():
    sample_payload = {
        "dynamodb": {
            "NewImage": {
                "attribute1": {"S": "val1"},
                "attribute2": {"S": "val2"}
            }
        }
    }

    encoded_payload = base64.b64encode(json.dumps(sample_payload).encode("utf-8")).decode("utf-8")

    event = {
        "Records": [
            {
                "eventID": "1",
                "eventSourceARN": "arn:aws:dynamodb:us-east-1:123456789012:table/datalake-ddb-integration-stream-notifications-referral/stream/2021-07-31T21:00:00.000",
                "kinesis": {
                    "data": encoded_payload
                }
            }
        ]
    }

    expected_athena_table_name = "dynamo_sls_referral"

    with patch.dict(os.environ, {
        "S3_RAW": "my-raw-bucket",
        "S3_PROCESSED": "my-processed-bucket",
        "AWS_REGION": "us-east-1"
    }), \
         patch('lambda_function.TABLE_MAPPING', {'datalake-ddb-integration-stream-notifications-referral': expected_athena_table_name}), \
         patch('lambda_function.parse_payload') as mock_parse_payload, \
         patch('lambda_function.apply_schema') as mock_apply_schema, \
         patch('lambda_function.write_processed_to_s3') as mock_write_processed, \
         patch('lambda_function.log_event') as mock_log_event:

        mock_df = MagicMock()
        mock_parse_payload.return_value = mock_df
        mock_apply_schema.return_value = mock_df

        result = lambda_handler(event, None)

        #assert result is True
        mock_log_event.assert_any_call("info", "event_id", "Processing event with ID: 1")
        mock_log_event.assert_any_call("info", "source_table_name", "Source DynamoDB table: datalake-ddb-integration-stream-notifications-referral")
        mock_write_processed.assert_called_once()
        mock_apply_schema.assert_called_once()


def test_lambda_handler_missing_mapping():
    sample_payload = {
        "dynamodb": {
            "NewImage": {
                "attribute1": {"S": "val1"},
                "attribute2": {"S": "val2"}
            }
        }
    }

    encoded_payload = base64.b64encode(json.dumps(sample_payload).encode("utf-8")).decode("utf-8")

    event = {
        "Records": [
            {
                "eventID": "1",
                "eventSourceARN": "arn:aws:dynamodb:us-east-1:123456789012:table/missing_table/stream/2021-07-31T21:00:00.000",
                "kinesis": {
                    "data": encoded_payload
                }
            }
        ]
    }

    with patch('lambda_function.TABLE_MAPPING', {}), \
         patch('lambda_function.parse_payload') as mock_parse_payload, \
         patch('lambda_function.log_event') as mock_log_event:

        mock_parse_payload.return_value = MagicMock()

        result = lambda_handler(event, None)

        assert result is False
        mock_log_event.assert_called_with("error", "missing_mapping", "No Athena table mapping found for DynamoDB table: missing_table")


def test_lambda_handler_schema_application_fails():
    sample_payload = {
        "dynamodb": {
            "NewImage": {
                "attribute1": {"S": "val1"},
                "attribute2": {"S": "val2"}
            }
        }
    }

    encoded_payload = base64.b64encode(json.dumps(sample_payload).encode("utf-8")).decode("utf-8")

    event = {
        "Records": [
            {
                "eventID": "1",
                "eventSourceARN": "arn:aws:dynamodb:us-east-1:123456789012:table/datalake-ddb-integration-stream-notifications-referral/stream/2021-07-31T21:00:00.000",
                "kinesis": {
                    "data": encoded_payload
                }
            }
        ]
    }

    expected_athena_table_name = "dynamo_sls_referral"
    with patch.dict(os.environ, {
        "S3_RAW": "my-raw-bucket",
        "S3_PROCESSED": "my-processed-bucket",
        "AWS_REGION": "us-east-1"
    }), \
         patch('lambda_function.TABLE_MAPPING', {'datalake-ddb-integration-stream-notifications-referral': expected_athena_table_name}), \
         patch('lambda_function.parse_payload') as mock_parse_payload, \
         patch('lambda_function.apply_schema') as mock_apply_schema, \
         patch('lambda_function.write_processed_to_s3') as mock_write_processed, \
         patch('lambda_function.log_event') as mock_log_event:

        mock_parse_payload.return_value = MagicMock()
        mock_apply_schema.side_effect = Exception("Schema mismatch")

        try:
            lambda_handler(event, None)
            assert False, "Expected ValueError but none was raised"
        except ValueError as e:
            assert str(e) == "Schema mismatch for dynamo_sls_referral"
            mock_log_event.assert_called_with("error", "lambda_handler_exception", "Unhandled exception: Schema mismatch for dynamo_sls_referral")

def test_lambda_handler_unhandled_exception():
    sample_payload = {
        "dynamodb": {
            "NewImage": {
                "attribute1": {"S": "val1"},
                "attribute2": {"S": "val2"}
            }
        }
    }

    encoded_payload = base64.b64encode(json.dumps(sample_payload).encode("utf-8")).decode("utf-8")

    event = {
        "Records": [
            {
                "eventID": "1",
                "eventSourceARN": "arn:aws:dynamodb:us-east-1:123456789012:table/datalake-ddb-integration-stream-notifications-referral/stream/2021-07-31T21:00:00.000",
                "kinesis": {
                    "data": encoded_payload
                }
            }
        ]
    }

    with patch('lambda_function.parse_payload') as mock_parse_payload, \
         patch('lambda_function.log_event') as mock_log_event:

        mock_parse_payload.side_effect = Exception("Test exception")

        try:
            lambda_handler(event, None)
            assert False, "Expected Exception was not raised"
        except Exception as e:
            assert str(e) == "Test exception", f"Unexpected exception message: {str(e)}"
            mock_log_event.assert_called_with(
                "error", 
                "lambda_handler_exception", 
                "Unhandled exception: Test exception"
            )


