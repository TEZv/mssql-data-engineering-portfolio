variable "subscription_id" { type = string }
variable "location" {
  type    = string
  default = "polandcentral"
}
variable "project_name" {
  type    = string
  default = "erpdwhlab"
}
variable "sql_admin_login" {
  type    = string
  default = "portfolioadmin"
}
variable "sql_admin_password" {
  type      = string
  sensitive = true
}
variable "entra_admin_name" {
  type        = string
  description = "Name of the administrator group used for SQL bootstrap."
}
variable "entra_admin_object_id" {
  type        = string
  description = "Object id of the administrator group; not a subscription id."
}
variable "alert_email" {
  type        = string
  default     = null
  description = "Optional private alert destination; supply at deployment, never commit. Without it the alert has no delivery recipient."
}
