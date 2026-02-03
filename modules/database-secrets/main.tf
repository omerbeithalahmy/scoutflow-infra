# ============================================================================
# Database secrets Module Core Resources
# Uses 'latest' tags, minimal resources, single replicas
# Cost-optimized for development and feature testing
# ============================================================================

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

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

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password_override != "" ? var.db_password_override : random_password.db_password.result
    database = var.db_name
  })
}
