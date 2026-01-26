# VPC Networking Module
# Uses official AWS VPC Terraform module for production-grade networking

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  # Use specified number of availability zones
  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # NAT Gateway configuration (single for dev, multi-AZ for stage/prod)
  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.single_nat_gateway ? false : true

  # Enable DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags for Kubernetes (required for EKS)
  public_subnet_tags = {
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    Name                                            = "${var.project_name}-${var.environment}-public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    Name                                            = "${var.project_name}-${var.environment}-private"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# Get list of available AZs
data "aws_availability_zones" "available" {
  state = "available"
}
