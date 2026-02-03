# Production Environment - ScoutFlow Infrastructure
# Production-grade configuration with HA and security hardening

# ============================================
# Networking Module
# ============================================

module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = ["143.0.0.0/24", "143.0.1.0/24"]
  private_subnet_cidrs = ["143.0.2.0/24", "143.0.3.0/24"]
  az_count             = 2
  single_nat_gateway   = false # Production: Multi-AZ NAT gateways for HA
  eks_cluster_name     = var.eks_cluster_name
}

# ============================================
# EKS Cluster Module
# ============================================

module "eks" {
  source = "../../modules/eks-cluster"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_version
  environment     = var.environment

  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnets
  private_subnets = module.networking.private_subnets

  node_instance_type = var.node_instance_type
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  node_desired_size  = var.node_desired_size

  cluster_endpoint_public_access = true
}

# ============================================
# Database Secrets Module
# ============================================

module "database_secrets" {
  source = "../../modules/database-secrets"

  project_name = var.project_name
  environment  = var.environment
  db_username  = "postgres"
  db_name      = "nba_stats"

  # For dev, you can override with a simple password or let it auto-generate
  # db_password_override = "devpassword123" # Uncomment to set a specific password
}

# ============================================
# Helm Addons Module
# ============================================

module "helm_addons" {
  source = "../../modules/helm-addons"

  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = module.eks.cluster_name
  vpc_id            = module.networking.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider

  enable_argocd             = true
  enable_monitoring         = var.enable_monitoring
  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  enable_external_secrets   = true

  depends_on = [module.eks]
}
