# 🏀 ScoutFlow Infrastructure

## 📋 Overview
This repository contains the **Infrastructure as Code (IaC)** for the ScoutFlow Application.
It uses **Terraform** to provision a complete, production-ready Kubernetes (EKS) environment on AWS.

## 🏗 Architecture
- **VPC**: 141.0.0.0/16 (US-East-1)
- **Subnets**:
  - 2x **Public** (NAT Gateways, Load Balancers)
  - 2x **Private** (EKS Worker Nodes, PostgreSQL DB)
- **Compute**: EKS Cluster (v1.28) with `t3.medium` Worker Nodes.
- **Security**: Strict IAM Roles (IRSA) and minimal-access Security Groups.
- **Ingress**: AWS Load Balancer Controller (Helm Chart).

## � Prerequisites
Before running, ensure you have:
1.  **Terraform** (v1.5+)
2.  **AWS CLI** (Configured with `aws configure`)
3.  **Kubectl** (To interact with the cluster later)

## 🚀 How to Run

### 1. Initialize
Downloads necessary providers (AWS, Helm, Kubernetes).
```bash
cd terraform
terraform init
```

### 2. Validate & Plan (Free)
Checks your code and simulates the changes. **No cost.**
```bash
terraform validate
terraform plan
```

### 3. Deploy (Cost $$)
Creates the actual resources in AWS.
**Warning:** This will incur costs (~$0.10/hr + EC2 fees).
```bash
terraform apply
# Type 'yes' to confirm
```

### 4. Connect to Cluster
Once deployed, configure your local `kubectl`:
```bash
aws eks update-kubeconfig --region us-east-1 --name scoutflow-eks-cluster
kubectl get nodes
```

## 🧹 How to Destroy (Save Money)
To delete **everything** and stop billing:
```bash
terraform destroy
# Type 'yes' to confirm
```
> **Note:** This may take 10-15 minutes.

## 📂 File Structure
- `vpc.tf`: Networking (Subnets, NATs, Routes).
- `eks.tf`: Cluster and Node Groups.
- `iam.tf`: Cluster & Node IAM Roles.
- `security-groups.tf`: Firewalls.
- `alb-controller.tf`: Helm installation of Ingress Controller.
- `alb-iam.tf`: Permissions for the Ingress Controller.
