#!/bin/bash
set -e  # Exit immediately on any command failure

# Usage : ./run.sh --account <ACCOUNT_ID> --region <REGION> --bucket <BUCKET_NAME>

# Ensure we are in the script's directory
cd "$(dirname "$0")"

# Default values
ACCOUNT_ID=""
REGION="us-east-2"
BUCKET_NAME="zaki-terraform-remote-state"

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
    *)
      echo "❌ Unknown argument: $1"
      echo "Usage: $0 [--account ID] [--region REGION] [--bucket NAME]"
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


# Check if the S3 bucket exists
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "✅ Bucket ${BUCKET_NAME} already exists. Skipping creation.."
else
  echo "🪣 Bucket ${BUCKET_NAME} does not exist. Creating..."
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    $( [[ "$REGION" != "us-east-1" ]] && echo "--create-bucket-configuration LocationConstraint=${REGION}" )
fi

echo "----------------------------------------------------------"
echo "👤 AWS Account ID:      ${ACCOUNT_ID}"
echo "🔏 Remote State Bucket: ${BUCKET_NAME}"
echo "🌏 Region:              ${REGION}"
echo "----------------------------------------------------------"
