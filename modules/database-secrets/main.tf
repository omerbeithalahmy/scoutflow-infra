# Database Secrets Module
# Creates AWS Secrets Manager secrets for database credentials

# Random password generation for database
resource "random_password" "db_password" {
  length  = 16
  special = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "scoutflow/${var.environment}/database"
  description             = "Database credentials for ${var.project_name} ${var.environment}"
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name        = "scoutflow-${var.environment}-database"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Store credentials in the secret
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password_override != "" ? var.db_password_override : random_password.db_password.result
    database = var.db_name
  })
}
