resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.6"

  # Ensure the cluster nodes are ready before installing
  depends_on = [
    aws_eks_node_group.scoutflow_eks_node_group
  ]
}
