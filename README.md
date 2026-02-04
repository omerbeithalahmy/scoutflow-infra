# ScoutFlow Infrastructure Repository

> **AWS foundation and Infrastructure as Code for the ScoutFlow NBA analytics platform**

Production-grade cloud infrastructure using Terraform, AWS EKS, and modular design for multi-environment scalability.

---

## 📋 Overview

This repository manages ScoutFlow's global infrastructure across three environments using **Terraform modules**:

- **Development** - Cost-optimized environment for feature testing
- **Staging** - High-availability pre-production environment
- **Production** - Mission-critical environment with full scaling and security

**Key Technologies:**
- ✅ Terraform (Infrastructure as Code)
- ✅ AWS EKS (Managed Kubernetes)
- ✅ AWS Secrets Manager (Security & Compliance)
- ✅ VPC Networking (Multi-AZ Isolation)
- ✅ S3 & DynamoDB (State Management & Locking)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│  AWS Cloud (Region: us-east-1)                      │
│  └─ Virtual Private Cloud (VPC)                     │
│     ├─ Public Subnets (NAT Gateway, ALB)            │
│     └─ Private Subnets (EKS Managed Nodes)          │
└─────────────────────────────────────────────────────┘
                        │
                        ↓ (Managed by Terraform)
┌─────────────────────────────────────────────────────┐
│  Kubernetes Cluster (AWS EKS)                       │
│                                                     │
│  Helm Addons ──→ Deploys ──→ ArgoCD, LB Controller  │
│                                                     │
│  Secrets Manager ──→ Stores ──→ DB Credentials      │
│              ↓                                      │
│         Automated Password Generation               │
└─────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
scoutflow-infra/
├── bootstrap/                    # One-time state backend infrastructure (S3 + DynamoDB)
├── modules/                      # Reusable Terraform modules
│   ├── networking/               # VPC, Subnets, NAT Gateways
│   ├── eks-cluster/              # EKS Control Plane & Node Groups
│   ├── helm-addons/              # ArgoCD, LB Controller, Metrics
│   └── database-secrets/         # AWS Secrets Manager integration
└── environments/
    ├── dev/                      # Development (t3.small, 2 nodes)
    ├── stage/                    # Staging (t3.medium, 2 nodes, monitoring enabled)
    └── prod/                     # Production (t3.medium, 3 nodes, HA)
```

---

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured ([Setup Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html))
2. **Terraform CLI** (>= 1.5.0) ([Download](https://www.terraform.io/downloads))
3. **kubectl** ([Install](https://kubernetes.io/docs/tasks/tools/))
4. **AWS IAM Permissions** - See [IAM Setup](#-iam-setup) below

### Deploy Infrastructure

```bash
# 1. Clone the repository
git clone https://github.com/omerbh7/scoutflow-infra
cd scoutflow-infra

# 2. Navigate to environment
cd environments/dev

# 3. Initialize Terraform
terraform init

# 4. Review plan
terraform plan

# 5. Deploy
terraform apply
```

### Verify Deployment

```bash
# Configure kubectl
$(terraform output -raw configure_kubectl)

# Check nodes
kubectl get nodes

# Verify ArgoCD
kubectl get pods -A | grep argocd
```

---

## 🔄 CI/CD Pipeline

<details>
<summary><b>GitHub Actions Workflows (Click to expand)</b></summary>

### 1. PR Validation (Automatic)

Runs automatically on every Pull Request:
- Format check (`terraform fmt`)
- Syntax validation (`terraform validate`)
- Plan generation for all environments

**Workflow:** [terraform-pr.yml](.github/workflows/terraform-pr.yml)

### 2. Manual Deploy

Deploy infrastructure from GitHub Actions:
1. Go to **Actions** tab → **Manual Deploy**
2. Click **Run workflow**
3. Select environment (dev/stage/prod)
4. Click **Run workflow** button
5. Review plan output
6. For production: Manual approval required

**Workflow:** [terraform-deploy.yml](.github/workflows/terraform-deploy.yml)

### Setup

Add AWS credentials to GitHub repository secrets:

**GitHub Repo → Settings → Secrets and variables → Actions**
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key

**Optional - Production Protection:**

To require approval for production deploys:
1. Go to **Settings → Environments**
2. Create environment named `prod`
3. Enable **Required reviewers**
4. Add yourself as reviewer

</details>

---

## 🔐 IAM Setup

<details>
<summary><b>📖 Required AWS Permissions (Click to expand)</b></summary>

### Core Services Required
- **VPC**: Create/modify VPCs, subnets, route tables, NAT gateways
- **EC2**: Instance management, security groups, network interfaces
- **EKS**: Create and manage EKS clusters and node groups
- **IAM**: Create roles, policies, instance profiles
- **Secrets Manager**: Create, read, update secrets
- **S3**: Manage buckets (for remote state)
- **DynamoDB**: Manage tables (for state locking)

### Quick Setup Options

**Option 1: AWS Console (Easiest)**
1. Log in to AWS Console → IAM → Users → Add User
2. Username: `terraform-scoutflow`
3. Enable "Programmatic access"
4. Attach **AdministratorAccess** policy (or custom policy below)
5. Save Access Key ID and Secret Access Key

**Option 2: Use Custom Policy**

<details>
<summary>Click for complete IAM policy JSON</summary>

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*", "elasticloadbalancing:*", "autoscaling:*", "eks:*"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:PassRole",
        "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:CreatePolicy",
        "iam:DeletePolicy", "iam:GetPolicy", "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile", "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
        "iam:TagRole", "iam:TagPolicy"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret", "secretsmanager:DeleteSecret",
        "secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue", "secretsmanager:UpdateSecret"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket", "s3:DeleteBucket", "s3:ListBucket",
        "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
        "s3:GetBucketVersioning", "s3:PutBucketVersioning",
        "s3:GetBucketPublicAccessBlock", "s3:PutBucketPublicAccessBlock",
        "s3:GetEncryptionConfiguration", "s3:PutEncryptionConfiguration"
      ],
      "Resource": ["arn:aws:s3:::scoutflow-terraform-state", "arn:aws:s3:::scoutflow-terraform-state/*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable", "dynamodb:DeleteTable", "dynamodb:DescribeTable",
        "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/scoutflow-terraform-locks"
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup", "logs:DescribeLogGroups", "logs:PutRetentionPolicy"],
      "Resource": "*"
    }
  ]
}
```

</details>

### Configure Credentials

```bash
aws configure
# Enter your Access Key ID, Secret Access Key, region (us-east-1), and output format (json)

# Verify
aws sts get-caller-identity
```

</details>

---

## 🔄 State Management

<details>
<summary><b>📖 Local vs Remote Backend (Click to expand)</b></summary>

### Current: Local Backend (Default)

State files stored locally in `environments/*/terraform.tfstate`

✅ Simple, fast, no AWS costs  
⚠️ No team collaboration, no state locking

### Optional: Remote Backend (S3 + DynamoDB)

For team collaboration and CI/CD:

**Step 1: Create Bootstrap Resources**

```bash
cd bootstrap
terraform init && terraform apply
```

**Step 2: Enable Backend**

Edit `environments/dev/backend.tf` and uncomment the terraform backend block

**Step 3: Migrate State**

```bash
cd environments/dev
terraform init -migrate-state  # Answer 'yes'
```

State now stored in S3 with DynamoDB locking!

📖 **Full guide**: See [bootstrap/README.md](bootstrap/README.md)

</details>

---

## 🌍 Environment Configurations

| Environment | Purpose | Node Type | Nodes | NAT Gateways | Monitoring |
|-------------|---------|-----------|-------|--------------|------------|
| **Dev** | Feature testing | t3.small | 2 | 1 (cost savings) | Disabled |
| **Stage** | QA validation | t3.medium | 2 | Multi-AZ | Prometheus + Grafana |
| **Prod** | Live workloads | t3.medium | 3 | Multi-AZ | Full stack + alerts |

<details>
<summary><b>📖 Detailed Environment Specs</b></summary>

### Development
- **Purpose:** Rapid iteration, frequently destroyed to save costs
- **Resources:** Minimal - 1 NAT gateway, 2 t3.small nodes
- **State:** Local backend (default)

### Staging
- **Purpose:** Pre-production testing, QA validation
- **Resources:** Production-like - Multi-AZ NAT, 2 t3.medium nodes
- **State:** Remote S3 backend recommended
- **Monitoring:** Prometheus & Grafana enabled

### Production
- **Purpose:** Mission-critical live workloads
- **Resources:** High availability - 3 AZs, 3 t3.medium nodes
- **State:** Remote S3 backend required
- **Security:** Public access restricted, enhanced logging
- **Monitoring:** Full observability stack with alerting

</details>

---

## 🛠️ Common Operations

<details>
<summary><b>📖 Useful Commands (Click to expand)</b></summary>

### Scale Cluster

```bash
# Edit variables
vim environments/prod/variables.tf
# Change: node_desired_size = 5

# Apply
terraform apply -target=module.eks
```

### Format & Validate

```bash
terraform fmt -recursive
terraform validate
```

### Access ArgoCD

```bash
# Get password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Destroy Environment

```bash
cd environments/dev
terraform destroy
```

</details>

---

## 🔐 Secret Management

All secrets are managed by **AWS Secrets Manager** (no hardcoded passwords!)

**How it works:**
1. Terraform generates random passwords
2. Stores in AWS Secrets Manager (`scoutflow/{env}/database`)
3. Outputs secret ARNs for app consumption
4. Encrypted at rest via AWS KMS

**Security benefits:**
- ✅ No secrets in Git
- ✅ Automated rotation-ready
- ✅ IAM-protected access
- ✅ Audit logging

---

## 🔗 Integration with Other Repos

### [scoutflow-app](https://github.com/omerbh7/scoutflow-app)
**Infrastructure Provides:** Node capacity, Load Balancer Controller, Secret ARNs

### [scoutflow-gitops](https://github.com/omerbh7/scoutflow-gitops)
**Infrastructure Provides:** ArgoCD Server, Namespaces, RBAC, External Secrets foundation

---

## ⚠️ Important Notes

> [!WARNING]
> **Production Safety**
> - Always run `terraform plan` before applying changes
> - Never apply directly to production without plan review
> - Use remote state (S3) for stage/prod environments

> [!CAUTION]
> **Billable Resources**
> - This creates AWS resources that incur charges
> - Remember to `terraform destroy` dev environments when not in use
> - Estimated cost: Dev (~$50/month), Prod (~$150/month)

---

## 🚨 Troubleshooting

<details>
<summary><b>📖 Common Issues (Click to expand)</b></summary>

### "AccessDenied" errors

**Cause:** Missing IAM permissions

**Fix:** Check which resource failed and add the required permission to your IAM policy. Common missing permissions:
- `eks:CreateCluster` - for EKS creation
- `iam:PassRole` - for service account roles
- `ec2:CreateVpc` - for VPC creation

### "Bucket already exists" (Bootstrap)

**Cause:** S3 bucket names are globally unique

**Fix:** Change `project_name` in `bootstrap/variables.tf` to include a unique suffix

### State lock errors

**Cause:** Another terraform process crashed

**Fix:**
```bash
terraform force-unlock LOCK_ID  # Use with caution!
```

</details>

---

## ✅ Production Checklist

Before deploying to production:

- [ ] Terraform fmt and validate pass
- [ ] Modules tested in dev/stage environments
- [ ] Remote state (S3 + DynamoDB) configured
- [ ] IAM roles follow least-privilege principle
- [ ] Secrets generated in AWS Secrets Manager
- [ ] Plan output reviewed for unexpected changes
- [ ] AWS quotas checked for region

---

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Official AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws)
- [Official AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws)

---

## 🤝 Contributing

1. Work on a feature branch
2. Use `terraform fmt` before committing
3. Test in `environments/dev`
4. Provide `terraform plan` output in PR description
5. Merge after approval
