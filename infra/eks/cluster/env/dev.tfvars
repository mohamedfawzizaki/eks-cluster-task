aws_region              = "us-east-2"
account_id              = "727245885999"
cluster_name            = "zaki-eks-cluster"
cluster_version         = "1.32"
environment             = "dev"

remote_state_bucket = "zaki-terraform-remote-state"

vpc_remote_state_key    = "vpc/vpc.tfstate"
vpc_remote_state_region = "us-east-2"

iam_remote_state_key    = "iam/eks/cluster-access/terraform.tfstate"
iam_remote_state_region = "us-east-2"

efs_file_system_id      = "fs-04d7482bc3ac608d3"
tags = {
  Owners = "DevOpsTeam"
}

eks_cluster_worker_nodes_min_size     = 2
eks_cluster_worker_nodes_max_size     = 2
eks_cluster_worker_nodes_desired_size = 2
