import sys
import os
import unittest
import boto3
from unittest.mock import MagicMock, patch
from datetime import datetime


sys.path.append(os.path.abspath("../"))
from lambda_function import (
    list_object_versions,
    convert_to_utc_components,
    copy_object_with_new_key,
    lambda_handler,
)


class TestRestoreObjectVersions(unittest.TestCase):

    @patch("lambda_function.s3_client")
    def test_list_object_versions_empty_result(self, mock_s3_client):
        """
        Test the function when the S3 bucket has no versions or delete markers.
        """
        # Mock the paginator to return an empty response
        paginator_mock = MagicMock()
        paginator_mock.paginate.return_value = [{}]
        mock_s3_client.get_paginator.return_value = paginator_mock

        # Call the function with the mock client
        result = list_object_versions(bucket_name="test-bucket")

        # Assert the result is an empty list
        self.assertEqual(result, [])

    @patch("lambda_function.s3_client")
    def test_generate_new_key_edge_cases(self, mock_s3_client):
        """
        Test edge cases for generating new keys for files with multiple dots or no extension.
        """
        # Mock the paginator to return specific versions and delete markers
        paginator_mock = MagicMock()
        paginator_mock.paginate.return_value = [
            {
                "Versions": [
                    {
                        "Key": "file.with.multiple.dots.txt",
                        "VersionId": "111",
                        "IsLatest": True,
                        "LastModified": datetime(2023, 1, 1, 12, 0, 0),
                        "Size": 123,
                    },
                    {
                        "Key": "filewithoutextension",
                        "VersionId": "222",
                        "IsLatest": False,
                        "LastModified": datetime(2023, 1, 2, 12, 0, 0),
                        "Size": 456,
                    },
                ],
                "DeleteMarkers": [
                    {
                        "Key": "another.file.with.dots",
                        "VersionId": "333",
                        "IsLatest": False,
                        "LastModified": datetime(2023, 1, 3, 12, 0, 0),
                    },
                ],
            }
        ]
        mock_s3_client.get_paginator.return_value = paginator_mock

        # Call the function with the mock client
        result = list_object_versions(bucket_name="test-bucket")

        # Expected result
        expected_result = [
            {
                "Key": "file.with.multiple.dots.txt",
                "VersionId": "111",
                "IsLatest": True,
                "LastModified": datetime(2023, 1, 1, 12, 0, 0),
                "Size": 123,
                "IsDeleteMarker": False,
            },
            {
                "Key": "filewithoutextension",
                "VersionId": "222",
                "IsLatest": False,
                "LastModified": datetime(2023, 1, 2, 12, 0, 0),
                "Size": 456,
                "IsDeleteMarker": False,
            },
            {
                "Key": "another.file.with.dots",
                "VersionId": "333",
                "IsLatest": False,
                "LastModified": datetime(2023, 1, 3, 12, 0, 0),
                "IsDeleteMarker": True,
            },
        ]

        # Assert the results match the expected output
        self.assertEqual(result, expected_result)

    def test_convert_to_utc_components_standard_time(self):
        """Test conversion during standard time."""
        date_string = "November 20, 2024, 19:07:25 (UTC+02:00)"
        result = convert_to_utc_components(date_string)
        expected = (2024, 11, 20, 17, 7, 25)  # UTC+2 -> UTC
        self.assertEqual(result, expected)

    def test_convert_to_utc_components_daylight_savings(self):
        """Test conversion during daylight saving time."""
        date_string = "July 1, 2024, 14:00:00 (UTC+03:00)"
        result = convert_to_utc_components(date_string)
        expected = (2024, 7, 1, 11, 0, 0)  # UTC+3 (DST) -> UTC
        self.assertEqual(result, expected)

    def test_convert_to_utc_components_negative_offset(self):
        """Test conversion with a negative timezone offset."""
        date_string = "November 20, 2024, 19:07:25 (UTC-05:00)"
        result = convert_to_utc_components(date_string)
        expected = (2024, 11, 21, 0, 7, 25)  # UTC-5 -> UTC
        self.assertEqual(result, expected)

    def test_convert_to_utc_components_midnight(self):
        """Test conversion at midnight with positive timezone offset."""
        date_string = "December 31, 2024, 00:00:00 (UTC+01:00)"
        result = convert_to_utc_components(date_string)
        expected = (2024, 12, 30, 23, 0, 0)  # UTC+1 -> UTC
        self.assertEqual(result, expected)

    def test_convert_to_utc_components_no_offset(self):
        """Test conversion with UTC timezone."""
        date_string = "November 20, 2024, 19:07:25 (UTC+00:00)"
        result = convert_to_utc_components(date_string)
        expected = (2024, 11, 20, 19, 7, 25)  # Already UTC
        self.assertEqual(result, expected)

    @patch("lambda_function.s3_client")
    def test_list_object_versions_empty_result(self, mock_s3_client):
        """Test list_object_versions with an empty result."""
        mock_s3_client.get_paginator.return_value.paginate.return_value = []
        result = list_object_versions("test-bucket", "test-prefix")
        self.assertEqual(result, [])

    def test_convert_to_utc_components_daylight_savings(self):
        """Test convert_to_utc_components for daylight savings time handling."""
        date_string = "November 3, 2024, 01:30:00 (UTC+01:00)"
        expected = (2024, 11, 3, 0, 30, 0)
        result = convert_to_utc_components(date_string)
        self.assertEqual(result, expected)

    @patch("lambda_function.s3_client")
    @patch("lambda_function.logger")
    def test_lambda_handler(self, mock_logger, mock_s3_client):
        """Test lambda_handler for end-to-end functionality."""
        # Mocking S3 client and event
        mock_s3_client.get_paginator.return_value.paginate.return_value = [
            {
                "Versions": [
                    {
                        "Key": "file1.txt",
                        "VersionId": "v1",
                        "IsLatest": False,
                        "LastModified": datetime(2024, 11, 15, 10, 0, 0),
                        "Size": 123,
                    }
                ],
                "DeleteMarkers": [],
            }
        ]
        event = {
            "s3_bucket": "test-bucket",
            "target_path": "test-path",
            "start_date": "November 14, 2024, 00:00:00 (UTC+00:00)",
            "end_date": "November 16, 2024, 23:59:59 (UTC+00:00)",
        }

        result = lambda_handler(event, None)
        self.assertTrue(result)
        mock_logger.info.assert_any_call("Successfully processed all objects.")


if __name__ == "__main__":
    unittest.main()
