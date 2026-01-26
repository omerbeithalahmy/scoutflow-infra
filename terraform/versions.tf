terraform {
  required_version = ">= 1.5.0"

  # backend "s3" {
  #   bucket         = "scoutflow-terraform-state" # Change this to your unique bucket name
  #   key            = "eks/terraform.tfstate"
  #   region         = "us-east-1"  #   encrypt        = true
  #   dynamodb_table = "scoutflow-terraform-locks" # Optional: For state locking
  # }
  # NOTE: Uncomment the above S3 backend configuration after creating the bucket

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}