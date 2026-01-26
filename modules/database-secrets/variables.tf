variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_password_override" {
  description = "Override the random password (leave empty to auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "nba_stats"
}

variable "recovery_window_in_days" {
  description = "Number of days to retain secret after deletion"
  type        = number
  default     = 7
}
