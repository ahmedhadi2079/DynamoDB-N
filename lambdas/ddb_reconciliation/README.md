# dynamodb-datalake-reconciliation

## Testing

1. Authenticate
```bash
aws configure sso --profile bb2-alpha-admin
```
As this is an existing function we can update code and invoke to test.
2. Deploy changes
```bash
cd ./lambda/dynamodb-datalake-reconciliation
zip -r dynamo_recon.zip *.py *.sql package

aws lambda update-function-code \
    --function-name  datalake-alpha-dynamodb-datalake-reconciliation \
    --zip-file fileb://dynamo_recon.zip \
    --profile bb2-alpha-admin

rm dynamo_recon.zip
```

3. Invoke:
```bash
aws lambda invoke \
    --cli-binary-format raw-in-base64-out \
    --function-name datalake-alpha-dynamodb-datalake-reconciliation \
    --profile bb2-alpha-admin \
    response.json
```

- Inpect Cloudwatch for execution

## Drop old table
Must happen as schema has changed for this table.
```python
import awswrangler as wr
import boto3
boto3.setup_default_session(profile_name="bb2-alpha-admin")
wr.catalog.delete_table_if_exists(database='datalake_reconciliation', table='dynamo_cards_recon')
wr.s3.delete_objects(['s3://bb2-alpha-datalake-reconciliation/dynamo_cards_recon/'])
```
