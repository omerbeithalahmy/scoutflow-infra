# ScoutFlow Infra (Infrastructure as Code)

**Purpose**: Terraform modules to provision AWS resources: VPC, EKS, RDS, ECR, monitoring.

## Key Resources
- VPC with NAT Gateways across AZs
- EKS cluster with managed nodes
- RDS PostgreSQL
- ECR for app images
- Prometheus/Grafana, ArgoCD via Helm

## Usage
```bash
cd terraform/envs/dev
terraform init
terraform plan
terraform apply
