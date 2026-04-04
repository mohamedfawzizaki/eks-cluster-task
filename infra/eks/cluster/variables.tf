variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.32"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}




variable "remote_state_bucket" {
  description = "S3 bucket for VPC and IAM remote state"
  type        = string
}

variable "iam_remote_state_key" {
  description = "S3 key for IAM remote state"
  type        = string
}

variable "iam_remote_state_region" {
  description = "Region for IAM remote state bucket"
  type        = string
}


variable "vpc_remote_state_key" {
  description = "S3 key for VPC remote state"
  type        = string
}

variable "vpc_remote_state_region" {
  description = "Region for VPC remote state bucket"
  type        = string
}

variable "efs_file_system_id" {
  description = "EFS file system ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "eks_cluster_worker_nodes_min_size" {
  description = "Minimum size of the node group"
  type        = number
  default     = 2
}

variable "eks_cluster_worker_nodes_max_size" {
  description = "Maximum size of the node group"
  type        = number
  default     = 2
}

variable "eks_cluster_worker_nodes_desired_size" {
  description = "Desired size of the node group"
  type        = number
  default     = 2
}
