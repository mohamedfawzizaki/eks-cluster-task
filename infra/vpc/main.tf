locals {
  name         = var.vpc_name
  region       = var.region
  cluster_name = var.cluster_name
  tags = {
    Owner       = var.owner
    Environment = var.environment
    Project     = var.project_name
  }
}

data "aws_availability_zones" "available" {}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.2.0"
  name    = local.name
  cidr    = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = [for i in range(4) : cidrsubnet(var.vpc_cidr, 6, i + 5)] # 10.11.20.0/22, 10.11.24.0/22, ...
  public_subnets  = [for i in range(2) : cidrsubnet(var.vpc_cidr, 6, i + 1)] # 10.11.4.0/22, 10.11.8.0/22

  create_database_subnet_route_table    = var.create_database_subnet_route_table
  create_elasticache_subnet_route_table = var.create_elasticache_subnet_route_table
  create_database_subnet_group          = var.create_database_subnet_group
  manage_default_network_acl            = var.manage_default_network_acl
  default_network_acl_tags              = { Name = "${local.name}-default" }
  manage_default_route_table            = var.manage_default_route_table
  default_route_table_tags              = { Name = "${local.name}-default" }
  manage_default_security_group         = var.manage_default_security_group
  default_security_group_tags           = { Name = "${local.name}-default" }
  enable_dns_hostnames                  = var.enable_dns_hostnames
  enable_dns_support                    = var.enable_dns_support
  enable_nat_gateway                    = var.enable_nat_gateway
  single_nat_gateway                    = var.single_nat_gateway
  one_nat_gateway_per_az                = var.single_nat_gateway ? false : true
  enable_vpn_gateway                    = var.enable_vpn_gateway
  enable_dhcp_options                   = var.enable_dhcp_options
  dhcp_options_domain_name              = var.dhcp_options_domain_name
  dhcp_options_domain_name_servers      = var.dhcp_options_domain_name_servers
  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_log_group = var.create_flow_log_cloudwatch_log_group
  create_flow_log_cloudwatch_iam_role  = var.create_flow_log_cloudwatch_iam_role
  flow_log_max_aggregation_interval    = var.flow_log_max_aggregation_interval
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
    "karpenter.sh/discovery"                      = local.cluster_name
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }
  tags = local.tags
  private_subnet_names = [
    "${local.name}-private-${local.region}a-1",
    "${local.name}-private-${local.region}a-2",
    "${local.name}-private-${local.region}b-1",
    "${local.name}-private-${local.region}b-2"
  ]
}
