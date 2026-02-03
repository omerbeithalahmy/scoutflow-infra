# Bootstrap Infrastructure

This directory contains Terraform configuration to create the foundational infrastructure for remote state management.

## What This Creates

- **S3 Bucket**: Stores Terraform state files with versioning and encryption enabled
- **DynamoDB Table**: Provides state locking to prevent concurrent modifications

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform >= 1.5.0 installed
- Appropriate IAM permissions (S3, DynamoDB)

## Usage

### 1. Initialize Terraform

```bash
cd bootstrap
terraform init
```

### 2. Review Resources

```bash
terraform plan
```

### 3. Create Bootstrap Resources

```bash
terraform apply
```

**Expected Output:**
- S3 bucket: `scoutflow-terraform-state`
- DynamoDB table: `scoutflow-terraform-locks`

### 4. Save Outputs

After `terraform apply`, note the outputs:

```bash
terraform output -json > bootstrap-outputs.json
```

## Next Steps

After bootstrap resources are created:

1. **Configure Backend in Environments**
   - Backend configuration files are already created in each environment
   - Located at `environments/{dev,stage,prod}/backend.tf`

2. **Migrate State (Optional)**
   - For each environment where you want to use remote state:
   
   ```bash
   cd environments/dev
   terraform init -migrate-state
   ```
   
   - Terraform will ask: "Do you want to copy existing state to the new backend?"
   - Answer: `yes`
   - Your local state will be safely migrated to S3

3. **Verify Remote State**
   
   ```bash
   # Check S3 bucket for state files
   aws s3 ls s3://scoutflow-terraform-state/
   
   # Should show: dev/, stage/, prod/ directories
   ```

## Important Notes

⚠️ **Bootstrap State is Local**
- The bootstrap directory uses local state (stored in `bootstrap/terraform.tfstate`)
- Keep this file safe or commit it (it contains no secrets)
- You only run bootstrap once

⚠️ **Do Not Delete These Resources**
- Deleting the S3 bucket or DynamoDB table will break state management for all environments
- If you need to destroy, first migrate all environments back to local state

## Troubleshooting

### Issue: "Bucket name already exists"
**Solution:** The S3 bucket name is globally unique. Change `project_name` in `variables.tf`

### Issue: "Access Denied"
**Solution:** Ensure your AWS credentials have permissions for S3 and DynamoDB

### Issue: State migration fails
**Solution:** 
1. Remove `.terraform/` directory
2. Run `terraform init -migrate-state` again
3. If still failing, keep local backend and troubleshoot separately

## Security

✅ Encryption at rest (AES256)  
✅ Versioning enabled (state recovery)  
✅ Public access blocked  
✅ State locking via DynamoDB
