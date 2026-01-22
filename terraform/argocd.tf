# ArgoCD - GitOps Continuous Delivery Tool
# Helm chart installation for managing Kubernetes applications

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.6"

  # Ensure the cluster is ready before installing
  depends_on = [module.eks]
}
