variable "subscription_id" {
  description = "Azure subscription used only for an authorized plan/apply."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "location" {
  description = "Azure region for the portfolio environment."
  type        = string
  default     = "polandcentral"
}

variable "project_name" {
  description = "Short lowercase prefix used in resource names."
  type        = string
  default     = "mssqlportfolio"

  validation {
    condition     = can(regex("^[a-z0-9]{3,18}$", var.project_name))
    error_message = "project_name must contain 3-18 lowercase letters or digits."
  }
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test"], var.environment)
    error_message = "Only disposable dev or test environments are allowed by this portfolio module."
  }
}

variable "sql_admin_login" {
  description = "SQL administrator login for the isolated lab server."
  type        = string
  default     = "portfolioadmin"
}

variable "sql_admin_password" {
  description = "Sensitive SQL administrator password. Pass through TF_VAR_sql_admin_password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sql_admin_password) >= 20
    error_message = "sql_admin_password must contain at least 20 characters."
  }
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
