# AWS Provider Configuration
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "scoutflow"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "omerbeithalahmy"
    }
  }
}

# Helm Provider Configuration
# Connects to EKS cluster to manage Helm releases
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}