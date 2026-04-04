data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = var.vpc_remote_state_key
    region = var.vpc_remote_state_region
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = var.iam_remote_state_key
    region = var.iam_remote_state_region
  }
}

data "aws_caller_identity" "current" {}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-al2023-x86_64-standard-${local.cluster_version}-v*"]
  }
}
