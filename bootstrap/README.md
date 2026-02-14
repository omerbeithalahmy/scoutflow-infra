# Bootstrap Infrastructure

> **One-time foundational infrastructure for Terraform remote state management**

This directory contains the Terraform configuration that creates the foundational AWS resources required for remote state storage and locking, enabling team collaboration and CI/CD automation across all environments.

---

## 📋 Overview

The bootstrap infrastructure is a **prerequisite layer** that must exist before configuring remote backends in the main environment configurations (dev, stage, prod). It creates two core AWS resources that enable Terraform's remote state functionality:

- **S3 Bucket** (`scoutflow-terraform-state`) - Centralized storage for all environment state files
- **DynamoDB Table** (`scoutflow-terraform-locks`) - Distributed locking mechanism to prevent concurrent modifications

**Key Characteristics:**
- ✅ One-time deployment (not per-environment)
- ✅ Uses local state (bootstrap state stored in `terraform.tfstate`)
- ✅ Minimal cost (~$0.30/month)
- ✅ Required for team collaboration and CI/CD
- ✅ Optional for solo development

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│  Bootstrap Infrastructure (One-Time Setup)          │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ S3 Bucket: scoutflow-terraform-state        │   │
│  │ ├─ dev/terraform.tfstate                    │   │
│  │ ├─ stage/terraform.tfstate                  │   │
│  │ └─ prod/terraform.tfstate                   │   │
│  │                                             │   │
│  │ Features:                                   │   │
│  │ • Versioning enabled (state recovery)       │   │
│  │ • Encryption at rest (AES256)               │   │
│  │ • Public access blocked                     │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ DynamoDB Table: scoutflow-terraform-locks   │   │
│  │                                             │   │
│  │ Purpose: State locking                      │   │
│  │ Billing: Pay-per-request                    │   │
│  │ Primary Key: LockID (String)                │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                        │
                        ↓ (Used by)
┌─────────────────────────────────────────────────────┐
│  Environment Configurations                         │
│  ├─ environments/dev/backend.tf                     │
│  ├─ environments/stage/backend.tf                   │
│  └─ environments/prod/backend.tf                    │
└─────────────────────────────────────────────────────┘
```

---

## 🔧 Components

### S3 Bucket (`scoutflow-terraform-state`)

**Purpose:** Centralized storage for Terraform state files across all environments.

<details>
<summary><b>📖 S3 Bucket Configuration Details (Click to expand)</b></summary>

**Resource Configuration:**

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state"
  
  tags = {
    Name        = "${var.project_name}-terraform-state"
    Environment = "bootstrap"
    Purpose     = "Terraform state storage"
  }
}
```

**Bucket Name:** `scoutflow-terraform-state` (globally unique)

**Features Enabled:**

1. **Versioning** (`aws_s3_bucket_versioning`)
   - Status: Enabled
   - Purpose: Maintains history of state file changes
   - Benefit: Allows rollback to previous state versions
   - Implementation: Separate resource for versioning configuration

2. **Server-Side Encryption** (`aws_s3_bucket_server_side_encryption_configuration`)
   - Algorithm: AES256
   - Key Management: AWS-managed keys (SSE-S3)
   - Scope: All objects encrypted by default
   - Compliance: Meets data-at-rest encryption requirements

3. **Public Access Block** (`aws_s3_bucket_public_access_block`)
   - `block_public_acls`: true
   - `block_public_policy`: true
   - `ignore_public_acls`: true
   - `restrict_public_buckets`: true
   - Result: Complete public access prevention

**State File Organization:**

```
s3://scoutflow-terraform-state/
├── dev/
│   └── terraform.tfstate
├── stage/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

Each environment uses a unique `key` path to isolate state files.

**Access Control:**
- IAM-based access only
- No bucket policies (relies on IAM)
- Terraform backend automatically authenticates using AWS credentials

**Cost:**
- Storage: ~$0.023/GB/month (Standard storage class)
- Typical usage: ~1-5 MB per environment
- Estimated cost: ~$0.02/month for storage

</details>

---

### DynamoDB Table (`scoutflow-terraform-locks`)

**Purpose:** Provides distributed locking to prevent concurrent Terraform operations on the same state file.

<details>
<summary><b>📖 DynamoDB Table Configuration Details (Click to expand)</b></summary>

**Resource Configuration:**

```hcl
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-terraform-locks"
    Environment = "bootstrap"
    Purpose     = "Terraform state locking"
  }
}
```

**Table Name:** `scoutflow-terraform-locks`

**Schema:**
- **Primary Key**: `LockID` (String)
  - Format: `<bucket>/<key>` (e.g., `scoutflow-terraform-state/dev/terraform.tfstate`)
  - Uniqueness: One lock per state file

**Billing Mode:** Pay-per-request
- No provisioned capacity
- Charged per read/write request
- Cost-effective for low-frequency operations
- No minimum cost

**Locking Mechanism:**

1. **Lock Acquisition:**
   - Terraform attempts to write item to DynamoDB with `LockID`
   - Uses conditional write (item must not exist)
   - If successful: Lock acquired, operation proceeds
   - If fails: Another process holds lock, operation waits

2. **Lock Contents:**
   ```json
   {
     "LockID": "scoutflow-terraform-state/dev/terraform.tfstate",
     "Info": "Operation: apply, User: terraform-user, Created: 2024-02-14T10:00:00Z",
     "Who": "terraform-user@hostname",
     "Version": "1.5.0",
     "Created": "2024-02-14T10:00:00Z",
     "Operation": "OperationTypeApply",
     "Path": "scoutflow-terraform-state/dev/terraform.tfstate"
   }
   ```

3. **Lock Release:**
   - Terraform deletes item from DynamoDB after operation completes
   - Automatic release on successful completion
   - Manual force-unlock available if needed

**High Availability:**
- DynamoDB is multi-AZ by default
- 99.99% availability SLA
- No maintenance windows

**Cost:**
- Write requests: $1.25 per million requests
- Read requests: $0.25 per million requests
- Typical usage: ~10-50 requests per `terraform apply`
- Estimated cost: ~$0.25/month

</details>

---

## 🔄 State Management Workflow

<details>
<summary><b>📖 How Remote State Works (Click to expand)</b></summary>

### Without Bootstrap (Local State)

```
Developer Machine
├── environments/dev/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfstate  ← State stored locally
```

**Limitations:**
- State file only on one machine
- No collaboration (conflicts if multiple people run Terraform)
- No state locking
- Manual backups required
- CI/CD cannot access state

### With Bootstrap (Remote State)

```
Developer Machine                    AWS Cloud
├── environments/dev/                ┌─────────────────────────┐
│   ├── main.tf                      │ S3 Bucket               │
│   ├── variables.tf                 │ └─ dev/terraform.tfstate│
│   └── backend.tf ─────────────────→│                         │
│       (points to S3)                └─────────────────────────┘
│                                     ┌─────────────────────────┐
└─ terraform apply ──────────────────→│ DynamoDB Table          │
    (acquires lock first)             │ └─ LockID: dev/...      │
                                      └─────────────────────────┘
```

**Benefits:**
- State centralized in S3
- Multiple team members can collaborate
- State locking prevents conflicts
- Automatic versioning (rollback capability)
- CI/CD can access state
- Encryption at rest

### Backend Configuration

Each environment references the bootstrap resources in `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "scoutflow-terraform-state"  # Created by bootstrap
    key            = "dev/terraform.tfstate"      # Environment-specific path
    region         = "us-east-1"
    dynamodb_table = "scoutflow-terraform-locks"  # Created by bootstrap
    encrypt        = true
  }
}
```

**Parameters Explained:**

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `bucket` | `scoutflow-terraform-state` | S3 bucket name (from bootstrap output) |
| `key` | `dev/terraform.tfstate` | Path within bucket (unique per environment) |
| `region` | `us-east-1` | AWS region where bucket exists |
| `dynamodb_table` | `scoutflow-terraform-locks` | DynamoDB table name (from bootstrap output) |
| `encrypt` | `true` | Enable server-side encryption for state file |

</details>

---

## 🔐 Security Implementation

<details>
<summary><b>📖 Security Features (Click to expand)</b></summary>

### Encryption

**At Rest:**
- S3 bucket: AES256 encryption (AWS-managed keys)
- DynamoDB: Encrypted by default (AWS-owned keys)
- State files: Encrypted when stored in S3

**In Transit:**
- All API calls use TLS
- Terraform backend uses HTTPS for S3 access

### Access Control

**S3 Bucket:**
- No public access (all 4 public access blocks enabled)
- IAM-based access only
- No bucket policies (relies on IAM user/role permissions)
- CloudTrail logging for audit

**DynamoDB Table:**
- IAM-based access only
- No resource-based policies
- CloudTrail logging for audit

**Required IAM Permissions:**

For Terraform operations (apply/plan):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::scoutflow-terraform-state",
        "arn:aws:s3:::scoutflow-terraform-state/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/scoutflow-terraform-locks"
    }
  ]
}
```

### State File Security

**What's Stored in State:**
- Resource IDs and ARNs
- Configuration values
- Computed attributes
- **Potentially sensitive data** (database passwords, API keys)

**Security Measures:**
- Encryption at rest (S3 SSE)
- Encryption in transit (TLS)
- Access control (IAM)
- Versioning (recovery from accidental exposure)
- No public access

> [!WARNING]
> **Sensitive Data in State**
> - Terraform state may contain sensitive values
> - Never commit state files to Git
> - Restrict IAM access to state bucket
> - Use AWS Secrets Manager for sensitive data (as implemented in database-secrets module)

</details>

---

## 📊 Cost Analysis

<details>
<summary><b>📖 Monthly Cost Breakdown (Click to expand)</b></summary>

### Estimated Costs

| Resource | Usage | Unit Cost | Monthly Cost |
|----------|-------|-----------|--------------|
| **S3 Storage** | ~5 MB (3 environments) | $0.023/GB | ~$0.0001 |
| **S3 Requests** | ~100 GET/PUT per month | $0.0004/1000 | ~$0.00004 |
| **S3 Versioning** | ~10 MB (old versions) | $0.023/GB | ~$0.0002 |
| **DynamoDB Writes** | ~50 writes per month | $1.25/million | ~$0.00006 |
| **DynamoDB Reads** | ~100 reads per month | $0.25/million | ~$0.00003 |
| **Total** | | | **~$0.30/month** |

### Cost Optimization Features

1. **S3 Versioning Lifecycle** (Not Implemented)
   - Could add lifecycle policy to delete old versions after 90 days
   - Would reduce versioning storage costs
   - Trade-off: Less state history

2. **DynamoDB Pay-Per-Request**
   - No provisioned capacity
   - No minimum cost
   - Scales to zero when not in use

3. **Single Bucket for All Environments**
   - Shared infrastructure across dev/stage/prod
   - Reduces S3 bucket costs
   - Isolation via key prefixes

### Cost Comparison

| Scenario | Monthly Cost |
|----------|--------------|
| **Local State** | $0 |
| **Remote State (Bootstrap)** | ~$0.30 |
| **Remote State + Team (5 people)** | ~$0.30 (same) |
| **Remote State + CI/CD** | ~$0.50 (more operations) |

**Conclusion:** Bootstrap cost is negligible compared to benefits of team collaboration and state safety.

</details>

---

## 🔗 Integration with Environments

<details>
<summary><b>📖 How Environments Use Bootstrap Resources (Click to expand)</b></summary>

### Backend Configuration Files

Each environment has a `backend.tf` file that references bootstrap resources:

**Dev Environment** (`environments/dev/backend.tf`):
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

**Stage Environment** (`environments/stage/backend.tf`):
```hcl
terraform {
  backend "s3" {
    bucket         = "scoutflow-terraform-state"
    key            = "stage/terraform.tfstate"  # Different key
    region         = "us-east-1"
    dynamodb_table = "scoutflow-terraform-locks"
    encrypt        = true
  }
}
```

**Prod Environment** (`environments/prod/backend.tf`):
```hcl
terraform {
  backend "s3" {
    bucket         = "scoutflow-terraform-state"
    key            = "prod/terraform.tfstate"  # Different key
    region         = "us-east-1"
    dynamodb_table = "scoutflow-terraform-locks"
    encrypt        = true
  }
}
```

### State Isolation

**Key Differences:**
- Same S3 bucket: `scoutflow-terraform-state`
- Different keys: `dev/`, `stage/`, `prod/`
- Same DynamoDB table: `scoutflow-terraform-locks`
- Different lock IDs: Based on full S3 path

**Result:**
- Each environment has isolated state
- Locking prevents concurrent operations on same environment
- Different environments can be modified simultaneously

### CI/CD Integration

**GitHub Actions** (`.github/workflows/terraform-deploy.yml`):
```yaml
- name: Terraform Init
  run: terraform init
  # Automatically uses backend configuration from backend.tf
  # Authenticates to S3/DynamoDB using GitHub OIDC
```

**Benefits:**
- CI/CD can access centralized state
- No state file in Git repository
- Consistent state across local and CI/CD
- State locking prevents race conditions

</details>

---

## ⚠️ Important Notes

> [!NOTE]
> **Bootstrap State is Local**
> - The bootstrap directory itself uses **local state**
> - Bootstrap state file: `bootstrap/terraform.tfstate`
> - This file should be committed to Git (contains no secrets)
> - Only resource IDs are stored (S3 bucket name, DynamoDB table name)

> [!WARNING]
> **One-Time Deployment**
> - Bootstrap resources are created once per AWS account/region
> - Do not run `terraform destroy` unless migrating all environments back to local state
> - Deleting bootstrap resources breaks remote state for all environments

> [!CAUTION]
> **S3 Bucket Name Uniqueness**
> - S3 bucket names are globally unique across all AWS accounts
> - Default name: `scoutflow-terraform-state`
> - If name is taken, modify `var.project_name` in `variables.tf`

---

## 📚 Additional Resources

- [Terraform S3 Backend Documentation](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [Terraform State Management](https://www.terraform.io/docs/language/state/index.html)
- [AWS S3 Encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html)

---
