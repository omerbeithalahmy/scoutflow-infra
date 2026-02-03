# ============================================================================
# Stage Environment Terraform Version Constraints
# Uses 'latest' tags, minimal resources, single replicas
# Cost-optimized for development and feature testing
# ============================================================================

terraform {
  required_version = ">= 1.5.0"



  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
