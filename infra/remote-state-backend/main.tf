locals {
  region        = "us-east-2"
  account_id    = data.aws_caller_identity.current.account_id
  bucket_name   = "${local.account_id}-zaki-eks-task-tfstate"
  dynamodb_name = "${local.account_id}-zaki-eks-task-tfstate-lock"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = local.bucket_name

  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = local.bucket_name

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = local.dynamodb_name
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = local.bucket_name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "RequireEncryption",
   "Statement": [
    {
      "Sid": "RequireEncryptedTransport",
      "Effect": "Deny",
      "Action": ["s3:*"],
      "Resource": ["arn:aws:s3:::${local.bucket_name}/*"],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      },
      "Principal": "*"
    },
    {
      "Sid": "RequireEncryptedStorage",
      "Effect": "Deny",
      "Action": ["s3:PutObject"],
      "Resource": ["arn:aws:s3:::${local.bucket_name}/*"],
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      },
      "Principal": "*"
    }
  ]
}
EOF
}


