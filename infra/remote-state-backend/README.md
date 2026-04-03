# Terraform Remote State Infrastructure

This Terraform deployment provisions the foundational infrastructure required for secure remote state management across all Terraform deployments.

## Overview

This deployment creates:
- **S3 Bucket**: Encrypted storage for Terraform state files with versioning enabled
- **DynamoDB Table**: State locking mechanism to prevent concurrent modifications
- **Security Policies**: Bucket policies enforcing encryption in transit and at rest
- **Public Access Block**: Complete prevention of public access to the state bucket

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Account                              │
│                                                             │
│  ┌─────────────────────────┐    ┌─────────────────────────┐ │
│  │      S3 Bucket          │    │    DynamoDB Table       │ │
│  │  {account-id}-zaki-eks- │    │  {account-id}-zaki-eks- │ │
│  │  task-tfstate           │    │  task-tfstate-lock      │ │
│  │                         │    │                         │ │
│  │ • Versioning: Enabled   │    │ • Hash Key: LockID      │ │
│  │ • Encryption: AES256    │    │ • Read/Write: 1 unit    │ │
│  │ • Public Access: Blocked│    │                         │ │
│  └─────────────────────────┘    └─────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Resource Naming Convention

All resources use the AWS account ID as a prefix to ensure uniqueness across accounts:
- **S3 Bucket**: `{account-id}-zaki-eks-task-tfstate`
- **DynamoDB Table**: `{account-id}-zaki-eks-task-tfstate-lock`

## Security Features

### S3 Bucket Security
- **Versioning**: Enabled to maintain state file history
- **Public Access Block**: All public access blocked at bucket level
- **Encryption in Transit**: SSL/TLS required for all operations
- **Encryption at Rest**: AES256 server-side encryption enforced
- **Bucket Policy**: Denies unencrypted uploads and non-HTTPS requests

### DynamoDB Table
- **Minimal Capacity**: 1 read/write unit for cost optimization
- **State Locking**: Prevents concurrent Terraform operations

## Files Structure

```
remote-state-backend/
├── main.tf           # Core infrastructure resources
├── provider.tf       # AWS provider configuration
├── backend.tf        # Backend configuration for this deployment
├── versions.tf       # Terraform and provider version constraints
├── run.sh           # Automated deployment script
└── README.md        # This documentation
```

## Prerequisites

1. **AWS CLI**: Configured with appropriate credentials
2. **Terraform**: Version >= 1.10.0
3. **AWS Permissions**: Ability to create S3 buckets and DynamoDB tables
4. **Account Access**: Must be authenticated to the target AWS account

## Deployment

### Option 1: Automated Deployment (Recommended)
```bash
./run.sh
```

The script will:
1. Detect the current AWS account ID
2. Check if the S3 bucket already exists
3. Create the bucket if it doesn't exist
4. Initialize Terraform with the remote backend
5. Apply the infrastructure changes

### Option 2: Manual Deployment
```bash
# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="${ACCOUNT_ID}-zaki-eks-task-tfstate"

# Create bucket if it doesn't exist
aws s3api create-bucket --bucket "${BUCKET}" --region us-east-2

# Initialize Terraform
terraform init \
  -backend-config="bucket=${BUCKET}" \
  -backend-config="key=zaki-terraform-remote-state/terraform.tfstate" \
  -backend-config="region=us-east-2" \
  -backend-config="encrypt=true" \
  -reconfigure

# Apply changes
terraform apply
```

## Usage in Other Deployments

Once this infrastructure is deployed, other Terraform deployments can use the remote state by adding this backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket  = "{account-id}-zaki-eks-task-tfstate"
    key     = "path/to/your/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
    dynamodb_table = "{account-id}-zaki-eks-task-tfstate-lock"
  }
}
```

## Important Notes

- **Bootstrap Deployment**: This deployment uses local state initially, then migrates to remote state
- **Account Specific**: Must be deployed once per AWS account
- **Region**: Currently configured for `us-east-2` region
- **Cost**: Minimal cost due to low-capacity DynamoDB and S3 storage pricing

## Troubleshooting

### Common Issues

1. **Bucket Already Exists**: If the bucket exists but in a different region, update the region in `main.tf`
2. **Permission Denied**: Ensure your AWS credentials have S3 and DynamoDB permissions
3. **State Lock**: If deployment fails, check for existing locks in DynamoDB table

### Cleanup
⚠️ **Warning**: Deleting this infrastructure will make all remote state files inaccessible!

```bash
terraform destroy
```

## Maintenance

- **Monitoring**: Monitor S3 and DynamoDB costs in AWS Cost Explorer
- **Backup**: S3 versioning provides automatic backup of state files
- **Updates**: Review and update Terraform/provider versions periodically

## Related Documentation

- [Terraform S3 Backend Documentation](https://www.terraform.io/docs/backends/types/s3.html)
- [AWS S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [DynamoDB State Locking](https://www.terraform.io/docs/backends/types/s3.html#dynamodb-state-locking)
