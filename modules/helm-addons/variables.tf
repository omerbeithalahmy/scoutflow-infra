variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider URL (without https://)"
  type        = string
}

# ============================================
# Helm Chart Versions
# ============================================

variable "alb_controller_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.7.1"
}

variable "argocd_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.6"
}

variable "monitoring_version" {
  description = "kube-prometheus-stack Helm chart version"
  type        = string
  default     = "56.0.0"
}

variable "cluster_autoscaler_version" {
  description = "Cluster Autoscaler Helm chart version"
  type        = string
  default     = "9.29.0"
}

# ============================================
# Feature Toggles
# ============================================

variable "enable_argocd" {
  description = "Enable ArgoCD deployment"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable Prometheus/Grafana stack"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler"
  type        = bool
  default     = false
}
