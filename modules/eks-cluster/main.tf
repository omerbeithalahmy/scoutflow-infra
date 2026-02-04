# ============================================================================
# EKS Cluster Module - Kubernetes Infrastructure Provisioning
# Provisions an AWS EKS cluster using the official Terraform AWS EKS module with managed node groups, IRSA support, and control plane logging.
# Configures public and private endpoint access, cluster autoscaling capabilities, and secure IMDSv2 metadata access for worker nodes.
# ============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = concat(var.public_subnets, var.private_subnets)

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true

  enable_irsa = true

  eks_managed_node_groups = {
    main_node_group = {
      instance_types = [var.node_instance_type]
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      subnet_ids = var.private_subnets

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
