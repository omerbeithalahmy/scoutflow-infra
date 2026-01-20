provider "aws" {
    region = var.region

    default_tags {
        tags = {
            Project = "scoutflow"
            Environment = "dev"
            ManagedBy = "terraform"
            Owner = "omerbeithalahmy"
        }
    }
}

provider "helm" {
    kubernetes {
        host = aws_eks_cluster.scoutflow_eks_cluster.endpoint
        cluster_ca_certificate = base64decode(aws_eks_cluster.scoutflow_eks_cluster.certificate_authority[0].data)
        
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
    }
    }
}