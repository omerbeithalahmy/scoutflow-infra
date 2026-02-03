# Production Environment Outputs

# ============================================
# VPC Outputs
# ============================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnets
}

# ============================================
# EKS Cluster Outputs
# ============================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = module.eks.configure_kubectl
}

# ============================================
# Database Secrets Outputs
# ============================================

output "db_secret_arn" {
  description = "ARN of the database credentials secret in AWS Secrets Manager"
  value       = module.database_secrets.secret_arn
}

output "db_secret_name" {
  description = "Name of the database credentials secret"
  value       = module.database_secrets.secret_name
}

output "db_username" {
  description = "Database username"
  value       = module.database_secrets.db_username
}

output "db_password" {
  description = "Database password for Helm deployment"
  value       = module.database_secrets.db_password
  sensitive   = true
}

# ============================================
# Helm Addons Outputs
# ============================================

output "grafana_admin_password" {
  description = "Grafana admin password (if monitoring is enabled)"
  value       = module.helm_addons.grafana_admin_password
  sensitive   = true
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is deployed"
  value       = module.helm_addons.argocd_namespace
}

output "external_secrets_namespace" {
  description = "Namespace where External Secrets Operator is deployed"
  value       = module.helm_addons.external_secrets_namespace
}

output "external_secrets_role_arn" {
  description = "ARN of the IAM role for External Secrets Operator"
  value       = module.helm_addons.external_secrets_role_arn
}
