
#!/bin/bash
set -euo pipefail

ENDPOINT="http://localhost:4566"
BUCKET="sprint5-terraform-state"
TABLE="terraform-state-lock"

# LocalStack test credentials
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_EC2_METADATA_DISABLED=true

echo "Checking LocalStack S3..."
aws --endpoint-url="$ENDPOINT" s3api list-buckets >/dev/null 2>&1 || {
  echo "LocalStack S3 is not ready at $ENDPOINT"
  exit 1
}

echo "Creating S3 bucket if needed..."
if ! aws --endpoint-url="$ENDPOINT" s3api head-bucket \
  --bucket "$BUCKET" >/dev/null 2>&1; then
  aws --endpoint-url="$ENDPOINT" s3api create-bucket \
    --bucket "$BUCKET"
else
  echo "Bucket already exists."
fi

echo "Enabling bucket versioning..."
aws --endpoint-url="$ENDPOINT" s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo "Enabling AES-256 encryption..."
aws --endpoint-url="$ENDPOINT" s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Blocking public access..."
aws --endpoint-url="$ENDPOINT" s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  '{"BlockPublicAcls":true,"IgnorePublicAcls":true,"BlockPublicPolicy":true,"RestrictPublicBuckets":true}'

echo "Creating DynamoDB lock table if needed..."
if ! aws --endpoint-url="$ENDPOINT" dynamodb describe-table \
  --table-name "$TABLE" >/dev/null 2>&1; then
  aws --endpoint-url="$ENDPOINT" dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
else
  echo "Lock table already exists."
fi

echo "Waiting for DynamoDB table..."
aws --endpoint-url="$ENDPOINT" dynamodb wait table-exists \
  --table-name "$TABLE"

echo "Verifying bucket encryption..."
aws --endpoint-url="$ENDPOINT" s3api get-bucket-encryption \
  --bucket "$BUCKET"

echo "Verifying public access block..."
aws --endpoint-url="$ENDPOINT" s3api get-public-access-block \
  --bucket "$BUCKET"

echo "Verifying DynamoDB table..."
aws --endpoint-url="$ENDPOINT" dynamodb describe-table \
  --table-name "$TABLE" \
  --query 'Table.TableStatus' \
  --output text

echo "Bootstrap completed successfully."

