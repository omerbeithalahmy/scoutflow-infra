output "alb_controller_role_arn" {
  description = "ARN of the IAM role for ALB Controller"
  value       = aws_iam_role.alb_controller_role.arn
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is deployed"
  value       = var.enable_argocd ? helm_release.argocd[0].namespace : null
}

output "grafana_admin_password" {
  description = "Grafana admin password (use to access Grafana UI)"
  value       = var.enable_monitoring ? random_password.grafana_admin_password[0].result : null
  sensitive   = true
}

output "monitoring_namespace" {
  description = "Namespace where monitoring stack is deployed"
  value       = var.enable_monitoring ? helm_release.kube_prometheus_stack[0].namespace : null
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the IAM role for Cluster Autoscaler"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}
