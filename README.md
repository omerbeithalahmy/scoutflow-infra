# ScoutFlow Infrastructure Repository

> **AWS foundation and Infrastructure as Code for the ScoutFlow NBA analytics platform**

Production-grade cloud infrastructure using Terraform, AWS EKS, and modular design for multi-environment scalability.

---

## 📋 Overview

This repository contains the complete infrastructure-as-code implementation for ScoutFlow, managing AWS resources across three environments (dev, stage, prod) using Terraform modules. The infrastructure provides a production-ready Kubernetes platform on AWS EKS with integrated monitoring, secrets management, and GitOps capabilities.

**Key Technologies:**
- ✅ Terraform (Infrastructure as Code)
- ✅ AWS EKS (Managed Kubernetes)
- ✅ AWS Secrets Manager (Security & Compliance)
- ✅ VPC Networking (Multi-AZ Isolation)
- ✅ S3 & DynamoDB (State Management & Locking)
- ✅ GitHub Actions (CI/CD Automation)

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
├── .github/
│   └── workflows/                # CI/CD pipelines
│       ├── terraform-pr.yml      # Automatic PR validation
│       └── terraform-deploy.yml  # Manual deployment
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

## 🔧 Infrastructure Modules

### Networking Module

**Location:** `modules/networking/`

**Purpose:** Creates a production-ready VPC with public and private subnets across multiple availability zones.

<details>
<summary><b>📖 Networking Module Details (Click to expand)</b></summary>

**Components:**

1. **VPC Configuration**
   - CIDR: `141.0.0.0/16` (dev), customizable per environment
   - DNS hostnames and DNS support enabled
   - Tagged for EKS cluster discovery

2. **Subnet Architecture**
   - **Public Subnets**: 2 subnets across 2 AZs
     - CIDR: `141.0.0.0/24`, `141.0.1.0/24`
     - Auto-assign public IPs enabled
     - Used for: NAT Gateways, Application Load Balancers
     - Tagged: `kubernetes.io/role/elb = 1`
   
   - **Private Subnets**: 2 subnets across 2 AZs
     - CIDR: `141.0.2.0/24`, `141.0.3.0/24`
     - No public IP assignment
     - Used for: EKS worker nodes, application pods
     - Tagged: `kubernetes.io/role/internal-elb = 1`

3. **NAT Gateway Configuration**
   - **Dev**: Single NAT gateway (cost optimization)
   - **Stage/Prod**: Multi-AZ NAT gateways (high availability)
   - Elastic IPs automatically allocated
   - Enables outbound internet access for private subnets

4. **Route Tables**
   - Public route table: Routes `0.0.0.0/0` to Internet Gateway
   - Private route tables: Routes `0.0.0.0/0` to NAT Gateway(s)
   - Automatic association with respective subnets

5. **Internet Gateway**
   - Attached to VPC for public subnet internet access
   - Required for NAT Gateway functionality

**Key Features:**
- Multi-AZ deployment for high availability
- Proper subnet tagging for EKS integration
- Cost-optimized NAT configuration for dev
- Production-ready networking for stage/prod

**Outputs:**
- `vpc_id`: VPC identifier for EKS cluster
- `public_subnets`: List of public subnet IDs
- `private_subnets`: List of private subnet IDs

</details>

---

### EKS Cluster Module

**Location:** `modules/eks-cluster/`

**Purpose:** Provisions a fully managed Kubernetes cluster using AWS EKS with managed node groups and essential addons.

<details>
<summary><b>📖 EKS Cluster Module Details (Click to expand)</b></summary>

**Components:**

1. **Control Plane Configuration**
   - Kubernetes version: 1.28 (configurable)
   - Cluster endpoint: Public and private access enabled
   - Cluster creator admin permissions: Enabled
   - IRSA (IAM Roles for Service Accounts): Enabled

2. **Control Plane Logging**
   - All log types enabled:
     - `api`: Kubernetes API server logs
     - `audit`: Audit logs for compliance
     - `authenticator`: Authentication logs
     - `controllerManager`: Controller manager logs
     - `scheduler`: Scheduler logs
   - Logs sent to CloudWatch Logs

3. **Managed Node Groups**
   - **Instance Types**: 
     - Dev: `t3.small` (2 vCPU, 2 GB RAM)
     - Stage/Prod: `t3.medium` (2 vCPU, 4 GB RAM)
   - **Capacity Type**: On-Demand (reliable, predictable)
   - **Scaling Configuration**:
     - Dev: Min 1, Max 3, Desired 2
     - Stage: Min 1, Max 4, Desired 2
     - Prod: Min 2, Max 5, Desired 3
   - **Subnet Placement**: Private subnets only (security)
   - **Metadata Options**: IMDSv2 required (security hardening)

4. **Cluster Addons**
   
   **CoreDNS**
   - DNS resolution for Kubernetes services
   - Most recent version auto-selected
   
   **kube-proxy**
   - Network proxy for Kubernetes services
   - Most recent version auto-selected
   
   **VPC CNI**
   - AWS VPC networking for pods
   - Assigns VPC IP addresses to pods
   - Most recent version auto-selected
   
   **EBS CSI Driver**
   - Persistent volume support using AWS EBS
   - IRSA role for secure AWS API access
   - Enables dynamic volume provisioning
   - Required for stateful workloads (databases, monitoring)

5. **EBS CSI Driver IAM Role**
   - Created using IRSA (IAM Roles for Service Accounts)
   - Service account: `ebs-csi-controller-sa` in `kube-system` namespace
   - Permissions: Create, attach, delete EBS volumes
   - Secure: No AWS credentials stored in cluster

**Key Features:**
- Production-ready cluster configuration
- Multi-AZ node distribution for high availability
- Secure metadata access (IMDSv2)
- Comprehensive logging for troubleshooting
- IRSA-based security model

**Outputs:**
- `cluster_name`: EKS cluster name
- `cluster_endpoint`: Kubernetes API endpoint
- `cluster_certificate_authority_data`: CA cert for kubectl
- `oidc_provider_arn`: OIDC provider ARN for IRSA
- `oidc_provider`: OIDC provider URL

</details>

---

### Helm Addons Module

**Location:** `modules/helm-addons/`

**Purpose:** Deploys essential Kubernetes platform services using Helm charts, including load balancing, GitOps, monitoring, and secrets management.

<details>
<summary><b>📖 Helm Addons Module Details (Click to expand)</b></summary>

**Components:**

#### 1. AWS Load Balancer Controller

**Purpose:** Manages AWS Application Load Balancers (ALB) and Network Load Balancers (NLB) for Kubernetes Ingress and Service resources.

**Configuration:**
- **Helm Chart**: `aws-load-balancer-controller` from AWS EKS charts
- **Version**: 1.6.2 (configurable via `alb_controller_version`)
- **Namespace**: `kube-system`
- **Service Account**: `aws-load-balancer-controller`

**IAM Configuration:**
- **IAM Policy**: Downloaded from official AWS repository
  - Source: `https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json`
  - Permissions: Create/manage ALB, NLB, target groups, security groups
- **IAM Role**: IRSA-based role for service account
  - Trust policy: EKS OIDC provider
  - Condition: Service account `system:serviceaccount:kube-system:aws-load-balancer-controller`

**Features:**
- Automatic ALB provisioning from Ingress resources
- Integration with VPC and subnets
- Security group management
- Target group health checks

**Wait Strategy:**
- 60-second wait after deployment before other addons
- Ensures controller is ready before dependent resources

#### 2. Storage Classes

**Purpose:** Provides default storage classes for persistent volumes using AWS EBS.

**gp3 Storage Class (Default):**
- **Provisioner**: `ebs.csi.aws.com`
- **Type**: gp3 (latest generation, cost-effective)
- **Reclaim Policy**: Delete (volumes deleted with PVC)
- **Volume Binding**: WaitForFirstConsumer (topology-aware)
- **Encryption**: Enabled
- **File System**: ext4
- **Default**: Yes (annotation set)

**standard Storage Class:**
- Same configuration as gp3
- Provided for compatibility
- Not set as default

**Dependencies:**
- Requires EBS CSI driver (deployed in EKS module)
- Waits for ALB controller deployment

#### 3. ArgoCD

**Purpose:** GitOps continuous delivery tool for Kubernetes applications.

**Configuration:**
- **Helm Chart**: `argo-cd` from ArgoProj
- **Version**: 5.46.0 (configurable via `argocd_version`)
- **Namespace**: `argocd` (auto-created)
- **Enabled**: Controlled by `enable_argocd` variable (default: true)

**Features:**
- Web UI for application management
- Git repository synchronization
- Multi-cluster support
- RBAC and SSO integration
- Application health monitoring

**Access:**
- Initial admin password stored in secret: `argocd-initial-admin-secret`
- UI accessible via port-forward or Ingress

#### 4. Monitoring Stack (kube-prometheus-stack)

**Purpose:** Complete monitoring and alerting solution for Kubernetes.

**Configuration:**
- **Helm Chart**: `kube-prometheus-stack` from Prometheus Community
- **Version**: 51.0.0 (configurable via `monitoring_version`)
- **Namespace**: `monitoring` (auto-created)
- **Enabled**: Controlled by `enable_monitoring` variable
  - Dev: Disabled (cost savings)
  - Stage/Prod: Enabled

**Components:**

**Grafana:**
- Admin password: Randomly generated (16 characters)
- Persistent storage: 10 GB
- Default dashboards: Enabled
- Timezone: UTC
- Sidecar: Auto-loads dashboards and datasources

**Prometheus:**
- Retention period: 15 days
- Retention size: 8 GB
- Storage: 10 GB persistent volume
- Scrape interval: 30 seconds (default)
- Evaluation interval: 30 seconds (default)

**Alertmanager:**
- Enabled for alert routing
- Default configuration

**Default Alert Rules:**
- Alertmanager alerts: Enabled
- Config reloaders: Enabled
- General alerts: Enabled
- Kubernetes alerts: Enabled
- API server availability: Enabled
- API server SLOs: Enabled
- Kubelet alerts: Enabled
- Kubernetes apps: Enabled
- Kubernetes resources: Enabled
- Kubernetes storage: Enabled
- Kubernetes system: Enabled
- Kube state metrics: Enabled
- Network alerts: Enabled
- Node alerts: Enabled
- Node exporter: Enabled
- Prometheus alerts: Enabled
- Prometheus operator: Enabled

**Disabled Components:**
- etcd monitoring (managed by AWS)
- kube-proxy monitoring
- kube-scheduler monitoring (managed by AWS)

**Wait Strategy:**
- `wait = false` to avoid 20-minute timeout
- Depends on ALB controller deployment

#### 5. Cluster Autoscaler

**Purpose:** Automatically adjusts cluster size based on pod resource requests.

**Configuration:**
- **Helm Chart**: `cluster-autoscaler` from Kubernetes Autoscaler
- **Version**: 9.29.0 (configurable via `cluster_autoscaler_version`)
- **Namespace**: `kube-system`
- **Enabled**: Controlled by `enable_cluster_autoscaler` variable (default: false)

**IAM Configuration:**
- **IAM Policy**: Custom policy with permissions:
  - Describe: Auto Scaling groups, instances, launch configurations
  - Modify: Set desired capacity, terminate instances
  - EC2: Describe instance types, images
  - EKS: Describe node groups
- **IAM Role**: IRSA-based role
  - Service account: `system:serviceaccount:kube-system:cluster-autoscaler`

**Features:**
- Auto-discovery of node groups by cluster name
- Region-aware configuration
- Scales up when pods are pending
- Scales down when nodes are underutilized

#### 6. External Secrets Operator

**Purpose:** Synchronizes secrets from AWS Secrets Manager to Kubernetes secrets.

**Configuration:**
- **Helm Chart**: `external-secrets` from External Secrets
- **Version**: 0.9.9 (configurable via `external_secrets_version`)
- **Namespace**: `external-secrets-system` (auto-created)
- **Enabled**: Controlled by `enable_external_secrets` variable (default: true)
- **Install CRDs**: Yes

**IAM Configuration:**
- **IAM Policy**: Custom policy with permissions:
  - `secretsmanager:GetSecretValue`: Read secret values
  - `secretsmanager:DescribeSecret`: Get secret metadata
  - `secretsmanager:ListSecrets`: List available secrets
  - Resource scope: `scoutflow/{environment}/database-*`
- **IAM Role**: IRSA-based role
  - Service account: `system:serviceaccount:external-secrets-system:external-secrets`

**Service Account Annotation:**
- Automatically annotates service account with IAM role ARN
- Enables IRSA authentication to AWS Secrets Manager

**Features:**
- Automatic secret synchronization
- No AWS credentials in cluster
- Supports multiple secret stores
- Refresh interval configurable

**Wait Strategy:**
- 600-second timeout
- Waits for CRD installation
- Depends on ALB controller deployment

</details>

---

### Database Secrets Module

**Location:** `modules/database-secrets/`

**Purpose:** Generates secure database credentials and stores them in AWS Secrets Manager for consumption by applications.

<details>
<summary><b>📖 Database Secrets Module Details (Click to expand)</b></summary>

**Components:**

1. **Random Password Generation**
   - Length: 32 characters
   - Special characters: Enabled
   - Override special characters: `!#$%&*()-_=+[]{}<>:?`
   - Excludes ambiguous characters for reliability

2. **AWS Secrets Manager Secret**
   - **Secret Name**: `scoutflow/{environment}/database`
     - Dev: `scoutflow/dev/database`
     - Stage: `scoutflow/stage/database`
     - Prod: `scoutflow/prod/database`
   - **Secret Value**: JSON format
     ```json
     {
       "DB_USER": "postgres",
       "DB_PASSWORD": "<generated-password>",
       "DB_NAME": "nba_stats"
     }
     ```
   - **Recovery Window**: 7 days (allows recovery if accidentally deleted)

3. **Encryption**
   - Encryption at rest: AWS KMS (default key)
   - Encryption in transit: TLS

**Key Features:**
- Automated password generation (no manual intervention)
- Secure storage with encryption
- Environment-specific secrets
- Recovery window for accidental deletion
- IAM-based access control

**Integration:**
- External Secrets Operator reads from these secrets
- Creates Kubernetes secrets in application namespaces
- Applications consume via environment variables

**Outputs:**
- `secret_arn`: ARN for IAM policy configuration
- `secret_name`: Name for External Secrets configuration

</details>

---

## 🌍 Environment Configurations

| Environment | Purpose | Node Type | Nodes | NAT Gateways | Monitoring | Autoscaler |
|-------------|---------|-----------|-------|--------------|------------|------------|
| **Dev** | Feature testing | t3.small | 2 | 1 (cost savings) | Disabled | Disabled |
| **Stage** | QA validation | t3.medium | 2 | Multi-AZ | Enabled | Disabled |
| **Prod** | Live workloads | t3.medium | 3 | Multi-AZ | Enabled | Disabled |

<details>
<summary><b>📖 Environment-Specific Details (Click to expand)</b></summary>

### Development Environment

**File:** `environments/dev/`

**Configuration:**
```hcl
project_name     = "scoutflow"
environment      = "dev"
vpc_cidr         = "141.0.0.0/16"
eks_cluster_name = "scoutflow-dev-eks-cluster"
eks_version      = "1.28"

# Node configuration
node_instance_type = "t3.small"
node_min_size      = 1
node_max_size      = 3
node_desired_size  = 2

# Feature flags
enable_monitoring         = false  # Cost optimization
enable_cluster_autoscaler = false  # Not needed for dev
```

**Characteristics:**
- Cost-optimized for frequent creation/destruction
- Single NAT gateway to reduce costs
- Minimal node sizes
- No monitoring stack
- Suitable for rapid iteration

**Estimated Cost:** ~$50-70/month

### Staging Environment

**File:** `environments/stage/`

**Configuration:**
```hcl
project_name     = "scoutflow"
environment      = "stage"
vpc_cidr         = "142.0.0.0/16"
eks_cluster_name = "scoutflow-stage-eks-cluster"
eks_version      = "1.28"

# Node configuration
node_instance_type = "t3.medium"
node_min_size      = 1
node_max_size      = 4
node_desired_size  = 2

# Feature flags
enable_monitoring         = true   # Production-like monitoring
enable_cluster_autoscaler = false  # Manual scaling
```

**Characteristics:**
- Production-like configuration
- Multi-AZ NAT gateways for HA testing
- Monitoring stack enabled
- Suitable for QA and pre-production validation

**Estimated Cost:** ~$100-120/month

### Production Environment

**File:** `environments/prod/`

**Configuration:**
```hcl
project_name     = "scoutflow"
environment      = "prod"
vpc_cidr         = "143.0.0.0/16"
eks_cluster_name = "scoutflow-prod-eks-cluster"
eks_version      = "1.28"

# Node configuration
node_instance_type = "t3.medium"
node_min_size      = 2
node_max_size      = 5
node_desired_size  = 3

# Feature flags
enable_monitoring         = true   # Full observability
enable_cluster_autoscaler = false  # Manual scaling for control
```

**Characteristics:**
- High availability configuration
- Multi-AZ deployment
- Full monitoring and alerting
- Higher minimum node count
- Suitable for live user traffic

**Estimated Cost:** ~$150-200/month

</details>

---

## 🔄 CI/CD Pipeline

<details>
<summary><b>📖 GitHub Actions Workflows (Click to expand)</b></summary>

### PR Validation Workflow

**File:** `.github/workflows/terraform-pr.yml`

**Triggers:**
- Pull requests to `main` branch
- Pushes to `main` branch

**Jobs:**

1. **Terraform Format Check**
   - Runs `terraform fmt -check -recursive`
   - Ensures consistent code formatting
   - Fails if formatting issues found

2. **Terraform Validation**
   - Runs `terraform validate` for each environment
   - Checks syntax and configuration validity
   - Validates module references

3. **Terraform Plan**
   - Generates plan for all environments (dev, stage, prod)
   - Shows what changes would be applied
   - Does not apply changes
   - Requires AWS credentials in GitHub secrets

**Purpose:**
- Catch errors before merge
- Ensure code quality
- Preview infrastructure changes

### Manual Deployment Workflow

**File:** `.github/workflows/terraform-deploy.yml`

**Triggers:**
- Manual workflow dispatch
- Input: Environment selection (dev/stage/prod)

**Jobs:**

1. **Terraform Apply**
   - Initializes Terraform
   - Generates plan
   - Applies changes to selected environment
   - Requires manual approval for production

**Protection:**
- Production environment requires reviewer approval
- Configured in GitHub repository settings
- Prevents accidental production deployments

**Purpose:**
- Controlled infrastructure deployment
- Audit trail for changes
- Separation of plan and apply

</details>

---

## 🔄 State Management

<details>
<summary><b>📖 Terraform State Configuration (Click to expand)</b></summary>

### Local State (Default)

**Current Configuration:**
- State files stored locally in `environments/*/terraform.tfstate`
- No remote backend configured by default
- Suitable for solo development

**Advantages:**
- Simple setup
- No AWS costs
- Fast operations

**Limitations:**
- No team collaboration
- No state locking
- Manual backups required

### Remote State (Optional)

**Configuration:** See [bootstrap/README.md](bootstrap/README.md)

**Components:**
- S3 bucket: `scoutflow-terraform-state`
- DynamoDB table: `scoutflow-terraform-locks`
- Encryption: AES256
- Versioning: Enabled

**Backend Configuration:**
```hcl
terraform {
  backend "s3" {
    bucket         = "scoutflow-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "scoutflow-terraform-locks"
    encrypt        = true
  }
}
```

**Advantages:**
- Team collaboration
- State locking (prevents conflicts)
- Version history
- CI/CD compatible

**State File Paths:**
- Dev: `s3://scoutflow-terraform-state/dev/terraform.tfstate`
- Stage: `s3://scoutflow-terraform-state/stage/terraform.tfstate`
- Prod: `s3://scoutflow-terraform-state/prod/terraform.tfstate`

</details>

---

## 🔐 Security Implementation

<details>
<summary><b>📖 Security Features (Click to expand)</b></summary>

### Network Security

1. **VPC Isolation**
   - Dedicated VPC per environment
   - Private subnets for worker nodes
   - Public subnets only for load balancers

2. **Security Groups**
   - Managed by EKS module
   - Minimal required ports
   - No direct SSH access to nodes

3. **NAT Gateways**
   - Outbound internet access for private subnets
   - No inbound access to worker nodes

### IAM Security

1. **IRSA (IAM Roles for Service Accounts)**
   - No AWS credentials stored in cluster
   - Fine-grained permissions per service
   - Automatic credential rotation

2. **Least Privilege**
   - Each addon has specific IAM policy
   - Scoped to required resources only
   - Regular permission audits

3. **Service Account Roles:**
   - ALB Controller: Load balancer management only
   - EBS CSI Driver: Volume management only
   - External Secrets: Secrets read-only access
   - Cluster Autoscaler: Auto Scaling group management only

### Encryption

1. **At Rest:**
   - EBS volumes: Encrypted (gp3 storage class)
   - S3 state bucket: AES256 encryption
   - Secrets Manager: AWS KMS encryption

2. **In Transit:**
   - TLS for all API communication
   - Encrypted VPC CNI traffic

### Secrets Management

1. **AWS Secrets Manager**
   - Centralized secret storage
   - Automatic encryption
   - Access logging via CloudTrail

2. **External Secrets Operator**
   - Synchronizes to Kubernetes secrets
   - No secrets in Git
   - IRSA-based authentication

3. **Password Generation**
   - Random 32-character passwords
   - Special characters included
   - Unique per environment

### Audit Logging

1. **EKS Control Plane Logs**
   - All log types enabled
   - Sent to CloudWatch Logs
   - Retention: 7 days (default)

2. **CloudTrail**
   - AWS API call logging
   - Tracks infrastructure changes
   - Compliance and forensics

</details>

---

## 📊 Monitoring & Observability

<details>
<summary><b>📖 Monitoring Stack Details (Stage/Prod Only)</b></summary>

### Components

**Prometheus:**
- Metrics collection and storage
- 15-day retention period
- 8 GB retention size
- 10 GB persistent storage
- Scrape interval: 30 seconds

**Grafana:**
- Visualization dashboards
- 10 GB persistent storage
- Pre-configured datasources
- Default dashboards enabled

**Alertmanager:**
- Alert routing and notifications
- Grouping and deduplication
- Silence management

**Node Exporter:**
- System-level metrics
- CPU, memory, disk, network
- Deployed as DaemonSet

**Kube State Metrics:**
- Kubernetes resource metrics
- Pod, deployment, node states
- Resource quotas and limits

### Pre-configured Dashboards

| Dashboard | ID | Purpose |
|-----------|-----|---------|
| Kubernetes / Compute Resources / Cluster | 7249 | Overall cluster health |
| Kubernetes / Compute Resources / Namespace (Pods) | 7249 | Per-namespace resource usage |
| Kubernetes / Compute Resources / Node | 7249 | Individual node metrics |
| Node Exporter / Nodes | 1860 | System-level metrics |
| Kubernetes / Persistent Volumes | 7249 | Storage monitoring |

### Alert Rules

**Critical Alerts:**
- `KubeNodeNotReady`: Node is not ready
- `KubePodCrashLooping`: Pod in CrashLoopBackOff
- `KubePersistentVolumeFillingUp`: PV > 85% full
- `KubeMemoryOvercommit`: Memory requests exceed capacity
- `KubeCPUOvercommit`: CPU requests exceed capacity

**Warning Alerts:**
- `KubeNodeMemoryPressure`: Node under memory pressure
- `KubeNodeDiskPressure`: Node running out of disk
- `KubePodNotReady`: Pod not ready for extended period
- `PrometheusTargetDown`: Scrape target is down

### Access

**Grafana:**
- Port forward: `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80`
- URL: `http://localhost:3000`
- Username: `admin`
- Password: Terraform output `grafana_admin_password`

**Prometheus:**
- Port forward: `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090`
- URL: `http://localhost:9090`

**Alertmanager:**
- Port forward: `kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093`
- URL: `http://localhost:9093`

</details>

---

## 🔗 Integration with Other Repositories

### [scoutflow-app](https://github.com/omerbeithalahmy/scoutflow-app)

**What Infrastructure Provides:**
- EKS cluster for running application pods
- Load Balancer Controller for Ingress resources
- Secret ARNs for database credentials
- Storage classes for persistent volumes
- Node capacity for workload scheduling

**What Application Uses:**
- Helm charts deployed via ArgoCD
- External Secrets for database credentials
- Persistent volumes for database storage
- Ingress for HTTP routing

### [scoutflow-gitops](https://github.com/omerbeithalahmy/scoutflow-gitops)

**What Infrastructure Provides:**
- ArgoCD server installation
- Kubernetes namespaces (dev, stage, prod)
- RBAC configuration
- External Secrets Operator foundation
- Monitoring stack for observability

**What GitOps Uses:**
- ArgoCD for continuous deployment
- External Secrets for secret synchronization
- Namespaces for environment isolation
- Prometheus/Grafana for monitoring

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
> - Estimated cost: Dev (~$50/month), Stage (~$100/month), Prod (~$150/month)

> [!NOTE]
> **State Management**
> - Bootstrap infrastructure required for remote state
> - See [bootstrap/README.md](bootstrap/README.md) for setup
> - Local state used by default

---

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Official AWS VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws)
- [Official AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [External Secrets Operator](https://external-secrets.io/)

---
