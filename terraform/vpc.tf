# VPC Module - Official AWS Module
# Documentation: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}_vpc"
  cidr = var.vpc_cidr

  # Use first 2 available AZs
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = ["141.0.2.0/24", "141.0.3.0/24"]
  public_subnets  = ["141.0.0.0/24", "141.0.1.0/24"]

  # Enable NAT Gateways for private subnet internet access
  enable_nat_gateway     = true
  single_nat_gateway     = false # One NAT Gateway per AZ for high availability
  one_nat_gateway_per_az = true

  # Enable DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags for Kubernetes (required for EKS)
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    Name                     = "${var.project_name}_public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    Name                              = "${var.project_name}_private"
  }

  tags = {
    Name = "${var.project_name}_vpc"
  }
}

# Get List of Available AZs
data "aws_availability_zones" "available" {
  state = "available"
}
