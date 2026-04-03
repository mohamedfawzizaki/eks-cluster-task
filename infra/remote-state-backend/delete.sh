#!/bin/bash
# Exit on any error
set -e

# Ensure we are in the script's directory
cd "$(dirname "$0")"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "❌ Error: Could not get AWS caller identity."
  echo "Make sure you have valid credentials. If you are using a profile, run:"
  echo "export AWS_PROFILE=your-profile-name"
  exit 1
fi
REGION="us-east-2"
BUCKET="${ACCOUNT_ID}-zaki-eks-task-tfstate"

# Check if the S3 bucket exists (required for remote state)
if ! aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  echo "❌ Bucket ${BUCKET} does not exist. Cannot initialize Terraform backend."
  exit 1
fi

# Initialize Terraform with backend config
terraform init \
  -backend-config="bucket=${BUCKET}" \
  -backend-config="key=zaki-terraform-remote-state/terraform.tfstate" \
  -backend-config="region=${REGION}" \
  -backend-config="encrypt=true" \
  -reconfigure

# Destroy the infrastructure managed by Terraform
terraform destroy -auto-approve

# Optional: To delete the S3 bucket as well
echo "🗑️ Emptying S3 bucket ${BUCKET} (including versions)..."

# Delete all object versions
VERSIONS=$(aws s3api list-object-versions --bucket "${BUCKET}" --output json --query 'Versions[].{Key:Key,VersionId:VersionId}' 2>/dev/null)
if [ "$VERSIONS" != "null" ] && [ -n "$VERSIONS" ]; then
  aws s3api delete-objects --bucket "${BUCKET}" --delete "{\"Objects\":$VERSIONS}" >/dev/null
fi

# Delete all delete markers
MARKERS=$(aws s3api list-object-versions --bucket "${BUCKET}" --output json --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' 2>/dev/null)
if [ "$MARKERS" != "null" ] && [ -n "$MARKERS" ]; then
  aws s3api delete-objects --bucket "${BUCKET}" --delete "{\"Objects\":$MARKERS}" >/dev/null
fi

echo "🗑️ Deleting S3 bucket ${BUCKET}..."
aws s3 rb s3://${BUCKET} --force
