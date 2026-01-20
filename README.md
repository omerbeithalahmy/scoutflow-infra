# ScoutFlow Infrastructure

## 🎯 Mission
Infrastructure as Code (Terraform) for deploying the ScoutFlow NBA player tracking application to AWS EKS.

## 🏗 Architecture
Primary components created by this infrastructure:
- **VPC Network**: Custom VPC (141.0.0.0/16) with Public/Private subnets across 2 AZs.
- **EKS Cluster**: Managed Kubernetes Service (v1.28+).
- **Worker Nodes**: Managed Node Group (t3.medium instances) in private subnets.
- **Security**: IAM Roles (IRSA), Security Groups, and Least Privilege policies.
- **Add-ons**: AWS Load Balancer Controller for Ingress management.

## 📂 Repository Structure
```
scoutflow-infra/
├── terraform/           # Core Infrastructure Code
├── helm/                # Helm values and overrides
├── scripts/             # Helper automation scripts
└── docs/                # Detailed documentation
```

## 🚀 Quick Start
This repository is being built step-by-step.
Current Status: **Initialization Phase**
