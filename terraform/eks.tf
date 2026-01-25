# EKS Module - Official AWS Module
# Documentation: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = "1.30"

  # Networking
  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  # Control Plane Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Cluster Access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # OIDC Provider (required for IRSA - IAM Roles for Service Accounts)
  enable_irsa = true

  # Managed Node Groups
  eks_managed_node_groups = {
    scoutflow_nodes = {
      name = "${var.project_name}-node-group"

      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"

      min_size     = 1
      max_size     = var.node_count + 1
      desired_size = var.node_count

      # Place nodes in private subnets only
      subnet_ids = module.vpc.private_subnets

      tags = {
        Name = "${var.project_name}-managed-node"
      }
    }
  }

  tags = {
    Name = var.eks_cluster_name
  }
}