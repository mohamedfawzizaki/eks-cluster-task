#!/bin/bash
# Exit on any error
set -e

# Usage : ./delete.sh --profile <PROFILE> --region <REGION> --bucket <BUCKET_NAME> --env <ENV_NAME> --force

# Ensure we are in the script's directory
cd "$(dirname "$0")"

# Default values
REGION="us-east-2"
BUCKET_NAME="zaki-terraform-remote-state"
ENV_NAME=""
FORCE=false
AWS_PROFILE=""

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --region)
      REGION="$2"
      shift 2
      ;;
    --bucket)
      BUCKET_NAME="$2"
      shift 2
      ;;
    --env)
      ENV_NAME="$2"
      shift 2
      ;;
    --force | -y)
      FORCE=true
      shift
      ;;
    --profile)
      AWS_PROFILE="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1"
      echo "Usage: $0 [--region REGION] [--bucket NAME] [--env ENV_NAME] [--profile PROFILE] [--force]"
      exit 1
      ;;
  esac
done

# Setup AWS CLI command with optional profile
AWS_CMD="aws"
if [ -n "$AWS_PROFILE" ]; then
  AWS_CMD="aws --profile $AWS_PROFILE"
  export AWS_PROFILE
fi

# Check if the S3 bucket exists (required for deletion)
if ! $AWS_CMD s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "ℹ️ Bucket ${BUCKET_NAME} does not exist. Nothing to delete."
  exit 0
fi

# Confirmation Prompt
if [ "$FORCE" = false ]; then
  read -p "⚠️ Are you sure you want to delete the remote state bucket '${BUCKET_NAME}'? This will PERMANENTLY destroy your Terraform history. (y/N): " confirm
  if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "❌ Deletion cancelled."
    exit 0
  fi
fi

# Optional: To delete the S3 bucket as well
echo "--------------------------------------------------------"
echo "🗑️ Preparing to delete S3 bucket: ${BUCKET_NAME}"
echo "🌏 Region: ${REGION}"
echo "--------------------------------------------------------"


# Initialize Terraform with backend config
terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=remote-state-backend/terraform.tfstate" \
  -backend-config="region=${REGION}" \
  -backend-config="encrypt=true" \
  -reconfigure

# Check if the environment-specific var file exists
if [[ -f "env/${ENV_NAME}.tfvars" ]]; then
  echo "📊 Using var-file: env/${ENV_NAME}.tfvars"
  terraform destroy --var-file="env/${ENV_NAME}.tfvars" --auto-approve
else
  echo "ℹ️ No environment-specific var-file found at env/${ENV_NAME}.tfvars. Running standard destroy."
  terraform destroy --auto-approve
fi

# Delete all object versions
echo "🔄 Emptying S3 bucket (versioned objects)..."
VERSIONS=$($AWS_CMD s3api list-object-versions --bucket "${BUCKET_NAME}" --output json --query 'Versions[].{Key:Key,VersionId:VersionId}' 2>/dev/null)
if [ "$VERSIONS" != "null" ] && [ -n "$VERSIONS" ]; then
  $AWS_CMD s3api delete-objects --bucket "${BUCKET_NAME}" --delete "{\"Objects\":$VERSIONS}" >/dev/null
fi

# Delete all delete markers
echo "🔄 Removing delete markers..."
MARKERS=$($AWS_CMD s3api list-object-versions --bucket "${BUCKET_NAME}" --output json --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' 2>/dev/null)
if [ "$MARKERS" != "null" ] && [ -n "$MARKERS" ]; then
  $AWS_CMD s3api delete-objects --bucket "${BUCKET_NAME}" --delete "{\"Objects\":$MARKERS}" >/dev/null
fi

echo "🗑️ Deleting S3 bucket ${BUCKET_NAME}..."
$AWS_CMD s3 rb s3://${BUCKET_NAME} --force

echo "✅ Done. Remote state infrastructure cleared."
