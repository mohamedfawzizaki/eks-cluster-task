#!/bin/bash
set -e  # Exit immediately on any command failure

# Ensure we are in the script's directory
cd "$(dirname "$0")"

# Default action to 'plan' if no argument is provided
ACTION=${1:-plan}

if [[ "$ACTION" != "plan" && "$ACTION" != "apply" ]]; then
  echo "❌ Invalid action: $ACTION"
  echo "Usage: $0 [plan|apply]"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "❌ Error: Could not get AWS caller identity."
  echo "Make sure you have valid credentials. If you are using a profile, run:"
  echo "export AWS_PROFILE=your-profile-name"
  exit 1
fi
REGION="us-east-2"
BUCKET="${ACCOUNT_ID}-zaki-eks-task-tfstate"

# Check if the S3 bucket exists
if aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  echo "✅ Bucket ${BUCKET} already exists. Skipping creation.."
else
  echo "🪣 Bucket ${BUCKET} does not exist. Creating..."
  aws s3api create-bucket \
    --bucket "${BUCKET}" \
    --region "${REGION}" \
    $( [[ "$REGION" != "us-east-1" ]] && echo "--create-bucket-configuration LocationConstraint=${REGION}" )
fi

# Initialize Terraform with backend config
terraform init \
  -backend-config="bucket=${BUCKET}" \
  -backend-config="key=zaki-terraform-remote-state/terraform.tfstate" \
  -backend-config="region=${REGION}" \
  -backend-config="encrypt=true" \
  -reconfigure

# Perform requested action
if [[ "$ACTION" == "apply" ]]; then
  echo "🚀 Applying Terraform configuration..."
  terraform apply -auto-approve
else
  echo "🔍 Planning Terraform configuration...."
  terraform validate
  terraform fmt
  terraform plan
fi

