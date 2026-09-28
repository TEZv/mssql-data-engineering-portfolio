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
