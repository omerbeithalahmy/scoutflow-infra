# EKS Cluster Module
# Uses official AWS EKS Terraform module for production-grade Kubernetes

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Networking
  vpc_id     = var.vpc_id
  subnet_ids = concat(var.public_subnets, var.private_subnets)

  # Control Plane Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Cluster Access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true

  # OIDC Provider (required for IRSA - IAM Roles for Service Accounts)
  enable_irsa = true

  # Managed Node Groups
  eks_managed_node_groups = {
    main_node_group = {
      name = "${var.cluster_name}-node-group"

      instance_types = [var.node_instance_type]
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Place nodes in private subnets only
      subnet_ids = var.private_subnets

      # Enable IMDSv2 for security
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      tags = {
        Name        = "${var.cluster_name}-managed-node"
        Environment = var.environment
      }
    }
  }

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}
