# 🏀 ScoutFlow Infrastructure

[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?logo=kubernetes)](https://kubernetes.io/)

> **Production-grade Infrastructure as Code for the ScoutFlow NBA player tracking application**

## 📋 Overview

This repository contains the complete Infrastructure as Code (IaC) implementation for deploying the **ScoutFlow Application** to AWS using **Terraform modules**. The infrastructure is designed following AWS best practices and uses official, community-maintained Terraform modules for maximum reliability and maintainability.

## 🏗 Architecture

![Architecture Diagram](https://img.shields.io/badge/Architecture-AWS_EKS-orange)

### Infrastructure Components

| Component | Implementation | Description |
|-----------|---------------|-------------|
| **VPC Network** | `terraform-aws-modules/vpc/aws` | Custom VPC (141.0.0.0/16) with multi-AZ subnets |
| **EKS Cluster** | `terraform-aws-modules/eks/aws` | Managed Kubernetes 1.28 with IAM RBAC |
| **Compute** | EKS Managed Node Group | `t3.medium` instances in private subnets |
| **Load Balancing** | AWS Load Balancer Controller | Ingress controller for ALB/NLB provisioning |
| **GitOps** | ArgoCD | Continuous deployment from Git repos |
| **Observability** | Prometheus & Grafana | Metrics collection and visualization |
| **Logging** | CloudWatch Logs | Centralized cluster and application logging |

### Network Architecture

- **VPC CIDR**: `141.0.0.0/16`
- **Public Subnets**: `141.0.0.0/24`, `141.0.1.0/24` (NAT Gateways, Load Balancers)
- **Private Subnets**: `141.0.2.0/24`, `141.0.3.0/24` (EKS Worker Nodes, Databases)
- **High Availability**: Multi-AZ deployment across 2 availability zones
- **NAT Gateway**: One per AZ for redundancy

## ✨ Key Features

- ✅ **Module-Based Design**: Uses official AWS Terraform modules for better maintainability
- ✅ **Security Best Practices**: Worker nodes in private subnets, IAM RBAC, security groups
- ✅ **High Availability**: Multi-AZ deployment with redundant NAT gateways
- ✅ **GitOps Ready**: ArgoCD pre-installed for continuous deployment
- ✅ **Observability**: Complete monitoring stack with Prometheus/Grafana
- ✅ **IRSA Enabled**: IAM Roles for Service Accounts for fine-grained permissions
- ✅ **CloudWatch Integration**: Cluster logging to CloudWatch Logs

## 🛠 Prerequisites

Before deploying, ensure you have:

1. **Terraform** >= 1.5.0
2. **AWS CLI** configured with appropriate credentials
   ```bash
   aws configure
   ```
3. **kubectl** for cluster interaction (post-deployment)

## 🚀 Deployment Guide

### 1. Clone the Repository
```bash
git clone https://github.com/omerbeithalahmy/scoutflow-infra.git
cd scoutflow-infra/terraform
```

### 2. Review Variables
Edit `variables.tf` to customize your deployment:
- `region`: AWS region (default: `us-east-1`)
- `project_name`: Project identifier (default: `scoutflow`)
- `eks_cluster_name`: EKS cluster name
- `node_instance_type`: Worker node instance type (default: `t3.medium`)
- `node_count`: Desired number of worker nodes (default: `2`)

### 3. Initialize Terraform
Download required providers and modules:
```bash
terraform init
```

### 4. Validate Configuration
Verify syntax and configuration:
```bash
terraform validate
terraform fmt
```

### 5. Review Plan (💰 No Cost)
Preview changes before applying:
```bash
terraform plan
```

### 6. Deploy Infrastructure (💵 Incurs AWS Costs)
**⚠️ Warning**: This will create billable AWS resources (~$0.10/hr for EKS control plane + EC2 costs)

```bash
terraform apply
# Type 'yes' to confirm
```

**Estimated deployment time**: 10-15 minutes

### 7. Configure kubectl
Once deployed, configure local kubectl access:
```bash
aws eks update-kubeconfig --region us-east-1 --name scoutflow-eks-cluster

# Verify connectivity
kubectl get nodes
kubectl get pods -A
```

## 🐙 Accessing ArgoCD

After deployment, ArgoCD is running in the `argocd` namespace:

1. **Port Forward the Service**:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

2. **Access UI**: Open `https://localhost:8080` in your browser

3. **Get Admin Password**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret \
     -o jsonpath="{.data.password}" | base64 -d
   ```
   - **Username**: `admin`
   - **Password**: (output from command above)

## 📊 Accessing Grafana

Prometheus and Grafana are deployed in the `monitoring` namespace:

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

- **URL**: `http://localhost:3000`
- **Username**: `admin`
- **Password**: `prom-operator` (default, change in production)

## 🧹 Destroying Infrastructure

To delete all resources and stop billing:

```bash
terraform destroy
# Type 'yes' to confirm
```

**⏱ Est. destruction time**: 10-15 minutes

## 📂 Repository Structure

```
scoutflow-infra/
├── terraform/
│   ├── alb-controller.tf     # AWS Load Balancer Controller (Helm)
│   ├── alb-iam.tf             # IRSA role for ALB Controller
│   ├── argocd.tf              # ArgoCD deployment (Helm)
│   ├── eks.tf                 # EKS module configuration
│   ├── observability.tf       # Prometheus/Grafana stack (Helm)
│   ├── outputs.tf             # Terraform outputs
│   ├── providers.tf           # Provider configurations
│   ├── variables.tf           # Input variables
│   ├── versions.tf            # Terraform and provider versions
│   └── vpc.tf                 # VPC module configuration
└── README.md                  # This file
```

## 🔑 Key Terraform Modules Used

- [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) - VPC networking
- [`terraform-aws-modules/eks/aws`](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws) - EKS cluster and node groups

## 💡 Design Decisions

### Why Terraform Modules?
- **Reduced Code**: ~200 lines of custom resources → ~100 lines using modules
- **Battle-Tested**: Community-maintained modules with thousands of users
- **Best Practices**: Modules implement AWS best practices by default
- **Faster Updates**: Module updates bring latest AWS features

### Why EKS on AWS?
- Managed Kubernetes control plane (automated updates, HA)
- Native AWS integration (IAM, VPC, ELB, CloudWatch)
- IRSA for fine-grained pod permissions
- Industry-standard container orchestration

### Cost Optimization
- **EKS Control Plane**: ~$0.10/hour ($73/month)
- **Worker Nodes**: 2x `t3.medium` ON_DEMAND ~$0.0832/hour ($60/month)
- **NAT Gateways**: 2x ~$0.045/hour ($66/month)
- **Total Est. Cost**: ~$200/month (can be reduced with Spot instances)

## 🤝 Contributing

This is a bootcamp project for learning purposes. For production use, consider:
- Enabling S3 backend for remote state (commented out in `versions.tf`)
- Implementing DynamoDB for state locking
- Using AWS Secrets Manager for sensitive values
- Enabling VPC Flow Logs for network monitoring

## 📄 License

This project is part of a DevOps bootcamp final project.

---

**Built with** ❤️ **for the DevOps Bootcamp Final Project**
