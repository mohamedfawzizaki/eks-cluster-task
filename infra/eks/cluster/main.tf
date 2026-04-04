locals {
  account         = var.account_id
  name            = var.cluster_name
  cluster_version = var.cluster_version
  region          = var.aws_region
  eks_ami_id      = data.aws_ami.eks_default.id
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids      = data.terraform_remote_state.vpc.outputs.public_and_private_subnets
  admin_sso_role  = data.terraform_remote_state.iam.outputs.admin_sso_role_arn
  power_sso_role  = data.terraform_remote_state.iam.outputs.power_sso_role_arn
  admin_oidc_role = data.terraform_remote_state.iam.outputs.admin_oidc_role_arn
  tags = merge(
    {
      Environment = var.environment
    },
    var.tags
  )
}
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                             = local.name
  kubernetes_version               = local.cluster_version
  endpoint_private_access          = true
  endpoint_public_access           = true
  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
    aws-efs-csi-driver = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }
  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true
  access_entries = {
    sso-admin = {
      kubernetes_groups = []
      principal_arn     = local.admin_sso_role
      policy_associations = {
        policy-one = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = []
            type       = "cluster"
          }
        }
      }
    },
    sso-power = {
      kubernetes_groups = []
      principal_arn     = local.power_sso_role
      policy_associations = {
        policy-one = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = []
            type       = "cluster"
          }
        }
      }
    },
    oidc-admin = {
      kubernetes_groups = []
      principal_arn     = local.admin_oidc_role
      policy_associations = {
        policy-one = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = []
            type       = "cluster"
          }
        }
      }
    }
  }
  endpoint_public_access_cidrs = [
    "0.0.0.0/0",
    format("%s/%s", data.terraform_remote_state.vpc.outputs.nat_public_ips[0], "32")
  ]

  # enable only authenticator logs for cost management
  enabled_log_types = [
    "authenticator"
  ]

  create_kms_key                = true
  kms_key_description           = "KMS Secrets encryption for Zaki EKS cluster."
  kms_key_enable_default_policy = true
  encryption_config = {
    resources = ["secrets"]
  }

  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_ids
  # Self managed node groups will not automatically create the aws-auth configmap so we need to

  # Extend cluster security group rules
  security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description = " To master"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  self_managed_node_groups = {

    standard-workers = {
      autoscaling_group_tags = {
        "k8s.io/cluster-autoscaler/enabled" : "true",
        "k8s.io/cluster-autoscaler/${local.name}" : "owned",
      }
      name            = "${local.name}-self-managed-workers"
      use_name_prefix = false
      subnet_ids      = data.terraform_remote_state.vpc.outputs.private_subnets
      min_size        = var.eks_cluster_worker_nodes_min_size
      max_size        = var.eks_cluster_worker_nodes_max_size
      desired_size    = var.eks_cluster_worker_nodes_desired_size
      cloudinit_pre_nodeadm = [{
        content      = <<-EOT
          ---
          apiVersion: node.eks.aws/v1alpha1
          kind: NodeConfig
          spec:
            kubelet:
              config:
                maxPods: 110
              flags:
                - --node-labels=node.kubernetes.io/lifecycle=spot,group=standard-workers
        EOT
        content_type = "application/node.eks.aws"
      }]
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 0
          spot_allocation_strategy = "capacity-optimized-prioritized"
        }
        launch_template = {
          override = [
            {
              instance_type     = "m5.xlarge"
              weighted_capacity = "1"
              priority          = 9
            },
            {
              instance_type     = "m5.2xlarge"
              weighted_capacity = "2"
              priority          = 8
            },
            {
              instance_type     = "m6a.2xlarge"
              weighted_capacity = "2"
              priority          = 7
            },
            {
              instance_type     = "t3.xlarge"
              weighted_capacity = "1"
              priority          = 6
            },
            {
              instance_type     = "c5.xlarge"
              weighted_capacity = "1"
              priority          = 5
            },
            {
              instance_type     = "c5.2xlarge"
              weighted_capacity = "2"
              priority          = 4
            },
            {
              instance_type     = "c6a.2xlarge"
              weighted_capacity = "2"
              priority          = 3
            },
            {
              instance_type     = "t3.2xlarge"
              weighted_capacity = "2"
              priority          = 2
            },
            {
              instance_type     = "t3a.2xlarge"
              weighted_capacity = "2"
              priority          = 1
            }
          ]
        }
      }

      # ami_id               = local.eks_ami_id
      ami_id               = local.eks_ami_id
      # instance_type                   = "t3.large"
      launch_template_name            = "self-${local.name}"
      launch_template_use_name_prefix = true
      launch_template_description     = "Self managed node group ${local.name} launch template"
      ebs_optimized                   = true
      vpc_security_group_ids          = [aws_security_group.additional.id]
      enable_monitoring               = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }
      create_iam_role          = true
      iam_role_name            = "self-managed-eks-${local.name}"
      iam_role_use_name_prefix = false
      iam_role_description     = "Self managed node group ${local.name}"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = {
        "AmazonEC2ContainerRegistryReadOnly" = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "AmazonSSMManagedInstanceCore"       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "AmazonEBSCSIDriverPolicy"           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
        "AutoScalingFullAccess"              = "arn:aws:iam::aws:policy/AutoScalingFullAccess",
        "ElasticLoadBalancingFullAccess"     = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
        "AmazonElasticFileSystemFullAccess"  = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
      }
      create_security_group          = true
      security_group_name            = "self-managed-node-group-${local.name}"
      security_group_use_name_prefix = false
      security_group_description     = "Self managed node group ${local.name} security group"
      security_group_rules = {
        phoneOut = {
          description = "Hello CloudFlare +"
          protocol    = "udp"
          from_port   = 53
          to_port     = 53
          type        = "egress"
          cidr_blocks = ["1.1.1.1/32"]
        }
        phoneHome = {
          description                   = "Hello cluster"
          protocol                      = "udp"
          from_port                     = 53
          to_port                       = 53
          type                          = "egress"
          source_cluster_security_group = true # bit of reflection lookup
        }
      }
      security_group_tags = {
        Purpose = "Protector of the kubelet"
      }

      timeouts = {
        create = "80m"
        update = "80m"
        delete = "80m"
      }

      tags = {
        ExtraTag = "Self managed node group ${local.name}"
      }
    }
  }
    # eks_managed_node_groups = {
    #   gpu-workers = {
    #     name            = "${local.name}-gpu-workers"
    #     use_name_prefix = false
    #     subnet_ids      = data.terraform_remote_state.vpc.outputs.private_subnets

    #     min_size     = 0
    #     max_size     = 2
    #     desired_size = 1

    #     instance_types = ["g6e.xlarge"]
    #     # capacity_type  = "SPOT" ,node.kubernetes.io/lifecycle=spot "g4dn.xlarge", "g4dn.2xlarge", "g5.xlarge", "g5.2xlarge", "g6e.xlarge", 

    #     ami_type                   = "AL2_x86_64_GPU"
    #     enable_bootstrap_user_data = true
    #     bootstrap_extra_args       = "--kubelet-extra-args '--node-labels=group=gpu-workers,nvidia.com/gpu=true --register-with-taints=nvidia.com/gpu=true:NoSchedule --max-pods=110'"
    #     pre_bootstrap_user_data = <<-EOT
    #     MIME-Version: 1.0
    #     Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

    #     --==MYBOUNDARY==
    #     Content-Type: text/x-shellscript; charset="us-ascii"

    #     #!/bin/bash
    #     export CONTAINER_RUNTIME="containerd"
    #     export USE_MAX_PODS=false

    #     --==MYBOUNDARY==--
    #     EOT
    #     labels = {
    #       group              = "gpu-workers"
    #       "nvidia.com/gpu"   = "true"
    #       workload           = "gpu"
    #     }
    #     taints = [
    #       {
    #         key    = "nvidia.com/gpu"
    #         value  = "true"
    #         effect = "NO_SCHEDULE"
    #       }
    #     ]

    #     additional_tags = {
    #       "k8s.io/cluster-autoscaler/enabled"       = "true"
    #       "k8s.io/cluster-autoscaler/${local.name}" = "owned"
    #       "karpenter.sh/discovery"                  = local.name
    #     }
    #     vpc_security_group_ids          = [aws_security_group.additional.id]
    #     enable_monitoring               = true
    #     block_device_mappings = {
    #       xvda = {
    #         device_name = "/dev/xvda"
    #         ebs = {
    #           volume_size           = 100
    #           volume_type           = "gp3"
    #           encrypted             = true
    #           delete_on_termination = true
    #         }
    #       }
    #     }
    #     metadata_options = {
    #       http_endpoint               = "enabled"
    #       http_tokens                 = "required"
    #       http_put_response_hop_limit = 2
    #       instance_metadata_tags      = "disabled"
    #     }
    #     create_iam_role          = true
    #     iam_role_name            = "gpu-managed-eks-${local.name}"
    #     iam_role_use_name_prefix = false
    #     iam_role_description     = "Self managed node group ${local.name}"
    #     iam_role_tags = {
    #       Purpose = "Protector of the kubelet"
    #     }
    #     iam_role_additional_policies = {
    #       "AmazonEC2ContainerRegistryReadOnly" = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    #       "AmazonSSMManagedInstanceCore"       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    #       "AmazonEBSCSIDriverPolicy"           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
    #       "AutoScalingFullAccess"              = "arn:aws:iam::aws:policy/AutoScalingFullAccess",
    #       "ElasticLoadBalancingFullAccess"     = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
    #       "AmazonElasticFileSystemFullAccess"  = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
    #     }
    #     tags = {
    #       Name    = "EKS GPU Spot Managed Node Group"
    #       Purpose = "GPU Spot Workers"
    #     }
    #   }
    # }
  tags = local.tags
}


# Supporting Resources

resource "aws_security_group" "additional" {
  name_prefix = "${local.name}-additional"
  vpc_id      = local.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      data.terraform_remote_state.vpc.outputs.vpc_cidr_block
    ]
  }

  tags = local.tags
}

# addons

resource "time_sleep" "wait_3_minutes" {
  depends_on = [module.eks]

  create_duration = "3m"
}


resource "aws_ec2_tag" "karpenter_cluster_sg_discovery" {
  resource_id = module.eks.cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = module.eks.cluster_name
}
resource "aws_ec2_tag" "karpenter_node_sg_discovery" {
  resource_id = module.eks.node_security_group_id
  key         = "karpenter.sh/discovery"
  value       = module.eks.cluster_name
}