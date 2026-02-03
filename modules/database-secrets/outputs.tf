output "secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  description = "Name of the database credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "db_username" {
  description = "Database username"
  value       = var.db_username
}

output "db_password" {
  description = "Database password (use for Helm if needed)"
  value       = var.db_password_override != "" ? var.db_password_override : random_password.db_password.result
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}
