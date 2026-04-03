#!/bin/bash
set -e  # Exit immediately on any command failure

# Usage : ./run.sh --action <plan|apply> --account <ACCOUNT_ID> --region <REGION> --bucket <BUCKET_NAME>

# Ensure we are in the script's directory
cd "$(dirname "$0")"

# Default values
ACTION=""
ACCOUNT_ID=""
REGION="us-east-2"
BUCKET_NAME=""
ENV_NAME="dev"

# Parse flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --account)
      ACCOUNT_ID="$2"
      shift 2
      ;;
    --action)
      ACTION="$2"
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


# Fallback to dynamic names if not provided
if [ -z "$BUCKET_NAME" ]; then
  BUCKET_NAME="${ACCOUNT_ID}-zaki-eks-task-tfstate"
fi

# Check if the S3 bucket exists
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "✅ Bucket ${BUCKET_NAME} already exists."
else
  echo "🪣 Bucket ${BUCKET_NAME} does not exist. Creating..."
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    $( [[ "$REGION" != "us-east-1" ]] && echo "--create-bucket-configuration LocationConstraint=${REGION}" )
fi

echo "----------------------------------------------------------"

# Initialize Terraform with backend config
echo "🏁 Initializing Terraform..."
terraform init \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=remote-state-backend/terraform.tfstate" \
  -backend-config="region=${REGION}" \
  -backend-config="encrypt=true" \
  -reconfigure

# Handle Action
VAR_FILE="env/${ENV_NAME}.tfvars"
TF_VAR_FILE_OPT=""
if [[ -f "$VAR_FILE" ]]; then
  echo "📊 Using var-file: $VAR_FILE"
  TF_VAR_FILE_OPT="-var-file=$VAR_FILE"
else
  echo "ℹ️ No environment-specific var-file found at $VAR_FILE."
fi

if [ "$ACTION" == "plan" ]; then
  echo "🧪 Running Terraform Plan..."
  terraform plan $TF_VAR_FILE_OPT
elif [ "$ACTION" == "apply" ]; then
  echo "🚀 Running Terraform Apply..."
  terraform apply $TF_VAR_FILE_OPT -auto-approve
else
  echo "❌ Error: Invalid or missing action. Use --action plan or --action apply"
  exit 1
fi

echo "✅ Done. Remote state infrastructure is ready."
# bucket name: zaki-terraform-remote-state
echo "bucket name: $BUCKET_NAME"
echo "region: $REGION"
echo "account id: $ACCOUNT_ID"
echo "terraform state key: remote-state-backend/terraform.tfstate"
echo "DynamoDB table name: zaki-terraform-remote-state-lock-table"