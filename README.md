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

**Infrastructure Management Flow:**
1. Terraform defines modules for Networking, EKS, and Addons
2. Environment-specific configurations (dev/stage/prod) reference modules
3. State is stored securely in S3 with DynamoDB locking
4. **All secrets are handled by AWS Secrets Manager** ✅

---

## 📁 Repository Structure

```
scoutflow-infra/
├── bootstrap/                    # One-time state backend infrastructure
│   ├── main.tf                  # S3 bucket + DynamoDB table for remote state
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md                # Bootstrap setup instructions
│
├── modules/                      # Reusable modular components
│   ├── networking/               # VPC, Subnets, NAT Gateways
│   ├── eks-cluster/              # EKS Control Plane & Node Groups
│   ├── helm-addons/              # ArgoCD, LB Controller, Metrics
│   └── database-secrets/         # AWS Secrets Manager integration
│
└── environments/
    ├── dev/                      # Development (minimal resources, single NAT)
    │   ├── backend.tf           # Remote backend config (commented by default)
    │   ├── main.tf
    │   └── variables.tf
    ├── stage/                    # Staging (2 replicas, monitor stack enabled)
    │   ├── backend.tf           # Remote backend config (commented by default)
    │   └── ...
    └── prod/                     # Production (HA, scaling, secure hardening)
        ├── backend.tf           # Remote backend config (commented by default)
        └── ...
```

---

## 🔄 State Management

This repository supports **two backend options** for Terraform state management:

### Option 1: Local Backend (Default - Active Now)

**Current configuration** - State files stored locally on your machine.

✅ **Pros:**
- Simple setup, no prerequisites
- Fast iteration for solo projects
- No AWS costs for state storage

⚠️ **Cons:**
- No team collaboration
- No state locking (concurrent apply protection)
- Risk of state loss if machine fails

**Usage:** Just use Terraform normally - already configured!

### Option 2: Remote Backend (Production-Ready)

**Available but inactive** - S3 + DynamoDB backend ready to enable.

✅ **Pros:**
- Team collaboration with shared state
- State locking prevents concurrent modifications
- State versioning for recovery
- CI/CD pipeline compatible
- Encrypted at rest

⚠️ **Setup Required:**

```bash
# 1. Create S3 bucket and DynamoDB table (one-time)
cd bootstrap
terraform init
terraform apply

# 2. Uncomment backend configuration
# Edit: environments/dev/backend.tf (remove # comments)

# 3. Migrate local state to S3
cd environments/dev
terraform init -migrate-state  # Type 'yes' when prompted
```

📖 **Detailed instructions:** See [bootstrap/README.md](bootstrap/README.md)

> [!NOTE]
> You can use different backends per environment (e.g., dev local, prod remote). Each `backend.tf` file is independent.

---

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with valid credentials ([Setup Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html))
2. **Terraform CLI** (>= 1.5.0) installed ([Download](https://www.terraform.io/downloads))
3. **kubectl** for cluster management ([Install](https://kubernetes.io/docs/tasks/tools/))
4. **Required IAM Permissions:**
   - VPC and EC2 full access
   - EKS cluster creation
   - IAM role/policy creation
   - Secrets Manager access

### Deploy Infrastructure (Local Backend)

```bash
# 1. Initialize development environment
cd environments/dev
terraform init

# 2. Review infrastructure plan
terraform plan

# 3. Apply changes
terraform apply
```

### Deploy Infrastructure (Remote Backend)

```bash
# 1. Create state backend (one-time)
cd bootstrap
terraform init && terraform apply

# 2. Uncomment backend.tf in your environment
vim environments/dev/backend.tf  # Remove # comments

# 3. Initialize with backend migration
cd environments/dev
terraform init -migrate-state  # Answer 'yes'

# 4. Deploy infrastructure
terraform plan
terraform apply
```

### Verify Deployment

```bash
# Configure kubectl connectivity
$(terraform output -raw configure_kubectl)

# Check EKS nodes
kubectl get nodes

# Verify installed addons (ArgoCD, etc)
kubectl get pods -A | grep argocd
```

---

## 🔐 Secret Management

### How Terraform Handles Secrets

**Configuration** (in modules):
```hcl
resource "aws_secretsmanager_secret" "db_pass" {
  name        = "scoutflow/${var.env}/database"
  description = "Managed by Terraform"
}
```

**What Happens:**
1. Terraform generates high-entropy random passwords
2. Creates/Updates AWS Secrets Manager entries per environment
3. Exports ARNs for consumption by the App/GitOps layers
4. **Sensitive values are marked as sensitive in Terraform outputs**

**Security Benefits:**
- ✅ No hardcoded passwords in any repository
- ✅ Automated rotation-ready configuration
- ✅ IAM-protected secret access
- ✅ Encrypted at rest via AWS KMS

---

## 🌍 Environment Configuration

### Development

**Purpose:** Rapid iteration and local testing

- **Networking:** 1 NAT Gateway (Cost Savings)
- **Node Type:** t3.small
- **Desired Nodes:** 2
- **Monitoring:** Disabled
- **Cleanup:** Frequently destroyed to save costs

### Staging

**Purpose:** QA validation and production simulation

- **Networking:** Multi-AZ NAT Gateways
- **Node Type:** t3.medium
- **Desired Nodes:** 2
- **Monitoring:** Prometheus & Grafana enabled
- **State:** Remote S3 state required

### Production

**Purpose:** Live application workloads

- **Networking:** High Availability (3 AZs)
- **Node Type:** t3.medium (Scalable)
- **Desired Nodes:** 3
- **Monitoring:** Full stack with Alerts
- **Security:** Public access restricted, Enhanced logging

---

## 🔄 Infrastructure Workflow

### Local Development

```
1. Modify Terraform module in `modules/`
   ↓
2. Change directory to `environments/dev`
   ↓
3. Run `terraform plan` to verify impact
   ↓
4. Run `terraform apply` to deploy changes
   ↓
5. Validate in EKS Console or via kubectl
```

### Production Promotion

```
1. Test module changes in Dev environment
   ↓
2. Commit and Merge to main branch
   ↓
3. Initialize `environments/prod`
   ↓
4. Perform strict `terraform plan` review
   ↓
5. Apply changes and verify cluster health
```

---

## 🛠️ Common Operations

### Update Cluster Capacity

```bash
# 1. Edit variables file
vi environments/prod/variables.tf

# 2. Modify node_desired_size
node_desired_size = 5

# 3. Apply change
terraform apply -target=module.eks
```

### Format and Validate

```bash
# Ensure clean code structure
terraform fmt -recursive

# Perform syntax and logic checks
terraform validate
```

### Accessing ArgoCD (Installed by Infra)

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward to UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

## 📊 Resource Allocation (EKS Nodes)

| Environment | Instance Type | Min Nodes | Desired | Max Nodes |
|-------------|---------------|-----------|---------|-----------|
| **Dev**     | t3.small      | 1         | 2       | 3         |
| **Stage**   | t3.medium     | 1         | 2       | 3         |
| **Prod**    | t3.medium     | 2         | 3       | 5         |

---

## 🔗 Integration with Other Repositories

### [scoutflow-app](https://github.com/omerbh7/scoutflow-app)

**Infrastructure Provides:**
- Node capacity for deployments
- LB Controller for Ingress
- Secret ARNs for DB connectivity

### [scoutflow-gitops](https://github.com/omerbh7/scoutflow-gitops)

**Infrastructure Provides:**
- ArgoCD Server & Controller
- Namespaces and RBAC
- Secret Store CSI driver / External Secrets foundation

---

## 🚨 Important Notes

### Production Safety

⚠️ **Always use `terraform plan`** - Never apply directly to production without a plan file review.

### State Management

🔒 **Choose Your Backend Strategy:**

**Local Backend (Current):**
- Active by default
- Suitable for solo development and demos
- State files in `environments/*/terraform.tfstate`

**Remote Backend (Recommended for Teams):**
- Bootstrap infrastructure ready in `bootstrap/`
- Backend configs prepared in `environments/*/backend.tf` (commented out)
- Enable by running bootstrap, uncommenting backend.tf, and migrating state
- See [State Management](#-state-management) section above

### Billable Resources

💰 **This repository creates billable AWS resources.**
- Remember to `terraform destroy` dev environments when not in use.

---

## 📝 Making Changes

### Adding a New Addon

1. Add Helm release to `modules/helm-addons/main.tf`
2. Define necessary variables
3. Apply to dev environment
4. Verify pod health in `kube-system` or `argocd` namespaces

### Modifying Networking

1. **CAUTION**: Modifying VPC CIDRs or Subnets may cause recreation
2. Always check the plan for `destroy and create replacement`
3. Prefer adding new subnets over modifying existing ones

---

## ✅ Production Checklist

Before applying to production:

- [ ] Terraform FMT and Validate pass
- [ ] Modules tested and verified in Stage
- [ ] Remote state locking is active
- [ ] AWS Quotas checked for Region
- [ ] IAM Roles follow least-privilege
- [ ] Secrets generated and stored in Secrets Manager
- [ ] Plan output reviewed for unexpected deletions

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
4. Provide the `terraform plan` output in the PR description
5. Merge after approval
