# Development Environment Configuration

terraform {
  required_version = ">= 1.5.0"

  # S3 Backend Configuration - UNCOMMENT when ready to use remote state
  # STEP 1: Create S3 bucket: aws s3api create-bucket --bucket scoutflow-terraform-state-dev --region us-east-1
  # STEP 2: Enable versioning: aws s3api put-bucket-versioning --bucket scoutflow-terraform-state-dev --versioning-configuration Status=Enabled
  # STEP 3: Create DynamoDB table: aws dynamodb create-table --table-name scoutflow-terraform-locks-dev --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
  # STEP 4: Uncomment the backend block below
  # STEP 5: Run: terraform init -migrate-state

  # backend "s3" {
  #   bucket         = "scoutflow-terraform-state-dev"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "scoutflow-terraform-locks-dev"
  # }

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
