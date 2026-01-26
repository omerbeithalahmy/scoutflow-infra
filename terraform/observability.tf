# Prometheus & Grafana - Observability Stack
# kube-prometheus-stack provides monitoring and alerting for Kubernetes

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "56.0.0"

  # Wait for cluster to be ready
  depends_on = [module.eks]
}