#!/bin/bash
# Exit on any error
set -e

# Usage : ./delete.sh --account <ACCOUNT_ID> --region <REGION> --bucket <BUCKET_NAME> --force

# Ensure we are in the script's directory
cd "$(dirname "$0")"

# Default values
ACCOUNT_ID=""
REGION="us-east-2"
BUCKET_NAME="zaki-terraform-remote-state"
FORCE=false

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --account)
      ACCOUNT_ID="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --bucket)
      BUCKET_NAME="$2"
      shift 2
      ;;
    --force | -y)
      FORCE=true
      shift
      ;;
    *)
      echo "❌ Unknown argument: $1"
      echo "Usage: $0 [--account ID] [--region REGION] [--bucket NAME] [--force]"
      exit 1
      ;;
  esac
done

# Fetch ACCOUNT_ID for display/context if not provided
if [ -z "$ACCOUNT_ID" ]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "❌ Error: Could not get AWS caller identity."
    echo "Make sure you have valid credentials. If you are using a profile, run: export AWS_PROFILE=your-profile"
    exit 1
  fi
fi

# Check if the S3 bucket exists (required for deletion)
if ! aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
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

# Delete all object versions
echo "🔄 Emptying S3 bucket (versioned objects)..."
VERSIONS=$(aws s3api list-object-versions --bucket "${BUCKET_NAME}" --output json --query 'Versions[].{Key:Key,VersionId:VersionId}' 2>/dev/null)
if [ "$VERSIONS" != "null" ] && [ -n "$VERSIONS" ]; then
  aws s3api delete-objects --bucket "${BUCKET_NAME}" --delete "{\"Objects\":$VERSIONS}" >/dev/null
fi

# Delete all delete markers
echo "🔄 Removing delete markers..."
MARKERS=$(aws s3api list-object-versions --bucket "${BUCKET_NAME}" --output json --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' 2>/dev/null)
if [ "$MARKERS" != "null" ] && [ -n "$MARKERS" ]; then
  aws s3api delete-objects --bucket "${BUCKET_NAME}" --delete "{\"Objects\":$MARKERS}" >/dev/null
fi

echo "🗑️ Deleting S3 bucket ${BUCKET_NAME}..."
aws s3 rb s3://${BUCKET_NAME} --force

echo "✅ Done. Remote state infrastructure cleared."
