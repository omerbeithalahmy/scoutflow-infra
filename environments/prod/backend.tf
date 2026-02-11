# ============================================================================
# Terraform Remote State Backend Configuration - Production Environment
# Stores state in S3 with DynamoDB locking for team collaboration and CI/CD.
# State file path: s3://scoutflow-terraform-state/prod/terraform.tfstate
# ============================================================================

terraform {
  backend "s3" {
    bucket         = "scoutflow-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "scoutflow-terraform-locks"
    encrypt        = true
  }
}
