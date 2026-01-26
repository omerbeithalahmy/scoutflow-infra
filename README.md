# 🏀 ScoutFlow Infrastructure

[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?logo=kubernetes)](https://kubernetes.io/)

> **Production-grade, multi-environment Infrastructure as Code for the ScoutFlow NBA player tracking application**

## 📋 Overview

This repository contains the complete Infrastructure as Code (IaC) implementation for deploying the **ScoutFlow Application** to AWS using **Terraform modules**. The infrastructure supports **three environments** (dev, stage, prod) with environment-specific configurations, follows AWS best practices, and uses official Terraform modules for maximum reliability.

## 🏗 Architecture

### Multi-Environment Structure

```
scoutflow-infra/
├── modules/                      # Reusable Terraform modules
│   ├── networking/               # VPC, subnets, NAT gateways
│   ├── eks-cluster/              # EKS cluster with managed node groups
│   ├── database-secrets/         # AWS Secrets Manager for DB credentials
│   └── helm-addons/              # ALB Controller, ArgoCD, monitoring, autoscaler
└── environments/
    ├── dev/                      # Development (cost-optimized)
    ├── stage/                    # Staging (production-like)
    └── prod/                     # Production (HA, secure)
```

### Infrastructure Components

| Component | Implementation | Dev | Stage | Prod |
|-----------|---------------|-----|-------|------|
| **VPC** | `terraform-aws-modules/vpc` | 141.0.0.0/16 | 142.0.0.0/16 | 143.0.0.0/16 |
| **NAT Gateways** | Multi-AZ support | 1 (cost-opt) | 2 (HA) | 2 (HA) |
| **EKS Cluster** | `terraform-aws-modules/eks` | 1.28 | 1.28 | 1.28 |
| **Node Type** | Managed node groups | t3.small | t3.medium | t3.medium |
| **Node Count** | Auto-scaling capable | 2 | 2 | 3 |
| **Load Balancer** | AWS LB Controller | ✅ | ✅ | ✅ |
| **GitOps** | ArgoCD | ✅ | ✅ | ✅ |
| **Monitoring** | Prometheus/Grafana | ❌ | ✅ | ✅ |
| **Autoscaling** | Cluster Autoscaler | ❌ | ❌ | ✅ |
| **DB Secrets** | AWS Secrets Manager | ✅ | ✅ | ✅ |

## ✨ Key Features

- ✅ **Multi-Environment**: Separate dev/stage/prod with appropriate configurations
- ✅ **Module-Based**: DRY principles with reusable Terraform modules
- ✅ **Production-Ready**: S3 backend support, state locking, encryption
- ✅ **Secure by Default**: Secrets Manager, IRSA, private subnets, secure passwords
- ✅ **GitOps Enabled**: ArgoCD pre-installed for continuous deployment
- ✅ **Observable**: Prometheus/Grafana stack (stage/prod)
- ✅ **Auto-Scaling**: Cluster Autoscaler in production
- ✅ **High Availability**: Multi-AZ deployment for stage/prod

## 🛠 Prerequisites

1. **Terraform** >= 1.5.0
   ```bash
   terraform version
   ```

2. **AWS CLI** configured with credentials
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, and region
   ```

3. **kubectl** for post-deployment cluster interaction
   ```bash
   kubectl version --client
   ```

## 🚀 Quick Start

### 1. Choose Your Environment

Pick an environment based on your needs:

- **dev**: Cost-optimized for development and testing
- **stage**: Production-like for pre-production testing
- **prod**: Full production setup with HA and security hardening

### 2. Initialize Terraform

```bash
cd environments/dev  # or stage/prod
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Deploy Infrastructure

⚠️ **Warning**: This creates billable AWS resources

```bash
terraform apply
# Type 'yes' to confirm
```

**Estimated deployment time**: 15-20 minutes

### 5. Configure kubectl

```bash
# The command is in the terraform output
terraform output -raw configure_kubectl | bash

# Verify connectivity
kubectl get nodes
kubectl get pods -A
```

## 📚 Detailed Deployment Guide

### Development Environment

**Purpose**: Local development and feature testing  
**Cost**: ~$100/month

```bash
cd environments/dev
terraform init
terraform plan
terraform apply

# Get database credentials for app deployment
terraform output -raw db_password
```

### Staging Environment

**Purpose**: Pre-production testing, QA validation  
**Cost**: ~$200/month

```bash
cd environments/stage
terraform init
terraform plan
terraform apply

# Access Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Get Grafana password
terraform output -raw grafana_admin_password
```

### Production Environment

**Purpose**: Live production workloads  
**Cost**: ~$250/month

```bash
cd environments/prod
terraform init
terraform plan
terraform apply

# Cluster autoscaler is enabled - nodes will scale automatically
kubectl get pods -n kube-system | grep autoscaler
```

## 🔐 Enabling S3 Remote State

**Why**: Secure, team-friendly state management with locking

### Step 1: Create S3 Bucket

```bash
# For dev environment (repeat for stage/prod)
aws s3api create-bucket \
  --bucket scoutflow-terraform-state-dev \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket scoutflow-terraform-state-dev \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket scoutflow-terraform-state-dev \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### Step 2: Create DynamoDB Table for Locking

```bash
aws dynamodb create-table \
  --table-name scoutflow-terraform-locks-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Step 3: Enable Backend in Terraform

Edit `environments/dev/versions.tf` and **uncomment** the backend block:

```hcl
backend "s3" {
  bucket         = "scoutflow-terraform-state-dev"
  key            = "dev/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "scoutflow-terraform-locks-dev"
}
```

### Step 4: Migrate State

```bash
terraform init -migrate-state
# Type 'yes' to migrate local state to S3
```

## 🗄️ Database Credentials Management

### How It Works

1. Terraform creates AWS Secrets Manager secret per environment
2. Random password is auto-generated (16 characters, secure)
3. Secret contains: `username`, `password`, `database`
4. Available to your application via:
   - Terraform outputs (for Helm deployment)
   - AWS SDK/CLI (for runtime access)
   - External Secrets Operator (advanced K8s integration)

### Access Credentials

```bash
# Get the secret ARN
terraform output db_secret_arn

# Get credentials for Helm deployment
DB_USER=$(terraform output -raw db_username)
DB_PASS=$(terraform output -raw db_password)

# Deploy your Helm chart with these values
helm install scoutflow ./helm/scoutflow \
  --set database.env.POSTGRES_USER="$DB_USER" \
  --set database.env.POSTGRES_PASSWORD="$DB_PASS"
```

## 🐙 Accessing Deployed Services

### ArgoCD (GitOps)

```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Access UI
open https://localhost:8080
# Username: admin
```

### Grafana (Monitoring - Stage/Prod Only)

```bash
# Port forward
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Get admin password (set by Terraform)
terraform output -raw grafana_admin_password

# Access UI
open http://localhost:3000
# Username: admin
```

### Prometheus (Metrics - Stage/Prod Only)

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
open http://localhost:9090
```

## 📊 Environment Comparison

| Feature | Dev | Stage | Prod |
|---------|-----|-------|------|
| **VPC CIDR** | 141.0.0.0/16 | 142.0.0.0/16 | 143.0.0.0/16 |
| **NAT Gateways** | 1 (cost-opt) | 2 (HA) | 2 (HA) |
| **Instance Type** | t3.small | t3.medium | t3.medium |
| **Min Nodes** | 1 | 1 | 1 |
| **Desired Nodes** | 2 | 2 | 3 |
| **Max Nodes** | 3 | 3 | 3 |
| **Monitoring** | ❌ | ✅ | ✅ |
| **Autoscaler** | ❌ | ❌ | ✅ |
| **Monthly Cost** | ~$100 | ~$200 | ~$250 |

## 🔒 Security Features

- **Private Subnets**: EKS nodes run in private subnets only
- **IRSA**: IAM Roles for Service Accounts (no static credentials)
- **Secrets Manager**: Encrypted database credentials with rotation support
- **Security Groups**: Least-privilege network access
- **IMDSv2**: Required for EC2 metadata access
- **Encrypted State**: S3 backend with encryption at rest
- **State Locking**: DynamoDB prevents concurrent modifications

## 🧹 Destroying Infrastructure

⚠️ **Warning**: This deletes all resources and data

```bash
cd environments/dev  # or stage/prod
terraform destroy
# Type 'yes' to confirm
```

**Estimated destruction time**: 10-15 minutes

## 🔧 Customization

### Modify Variables

Edit `environments/<env>/variables.tf` or create a `.tfvars` file:

```hcl
# custom.tfvars
node_instance_type = "t3.large"
node_desired_size  = 5
enable_monitoring  = true
```

Apply with custom variables:

```bash
terraform apply -var-file=custom.tfvars
```

### Add New Modules

Create a new module in `modules/` directory and reference it in your environment:

```hcl
module "my_module" {
  source = "../../modules/my-module"
  # ... variables
}
```

## 🎓 Learning Resources

### Terraform Modules Used

- [terraform-aws-modules/vpc](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) - VPC networking
- [terraform-aws-modules/eks](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws) - EKS cluster

### Documentation

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🤝 Contributing

This is a DevOps bootcamp final project. For production use, consider adding:

- VPC Flow Logs for network monitoring
- AWS GuardDuty for threat detection
- AWS Config for compliance tracking
- Backup strategy for stateful workloads
- Multi-region disaster recovery

## 📝 Cost Optimization Tips

1. **Use Spot Instances**: Change `node_capacity_type = "SPOT"` in dev environment
2. **Schedule Downtime**: Destroy dev environment overnight
3. **Right-Size Nodes**: Monitor actual usage and adjust instance types
4. **Single NAT Gateway**: Dev environment already uses this
5. **Reserved Instances**: For long-running prod workloads

## 📄 License

This project is part of a DevOps bootcamp final project.

---

**Built with** ❤️ **for the DevOps Bootcamp by Omer Beit-Halahmy**

## 🚦 Quick Commands Reference

```bash
# Initialize environment
cd environments/dev && terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show outputs
terraform output

# Destroy infrastructure
terraform destroy

# Configure kubectl
$(terraform output -raw configure_kubectl)

# Get DB credentials
terraform output -raw db_password
```
