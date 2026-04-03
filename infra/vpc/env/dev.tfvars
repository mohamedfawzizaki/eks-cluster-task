# Project Information
vpc_name     = "zaki-eks-task_vpc"
cluster_name = "zaki-eks-cluster"
project_name = "zaki-eks-cluster"
environment  = "dev"
owner        = "DevOpsTeam"
region       = "us-east-2"

# Network Configuration
vpc_cidr           = "10.11.0.0/16"
single_nat_gateway = true

# Networking Features
enable_dns_hostnames = true
enable_dns_support   = true
enable_nat_gateway   = true

# DHCP & DNS
enable_dhcp_options              = false
dhcp_options_domain_name         = "service.consul"
dhcp_options_domain_name_servers = ["127.0.0.1", "10.11.0.2"]

# Flow Logs
enable_flow_log                      = false
create_flow_log_cloudwatch_log_group = false
create_flow_log_cloudwatch_iam_role  = false
