output "scoutflow_eks_cluster" {
    description = "EKS cluster name"
    value = aws_eks_cluster.scoutflow_eks_cluster.name
}

output "cluster_endpoint" {
    description = "EKS cluster endpoint"
    value = aws_eks_cluster.scoutflow_eks_cluster.endpoint
}

output "cluster_id" {
    description = "EKS cluster ID"
    value = aws_eks_cluster.scoutflow_eks_cluster.id
}