locals { prefix = "${var.project_name}-${random_string.suffix.result}" }
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = { purpose = "independent-portfolio", environment = "disposable-dev", managed_by = "terraform" }
}
data "azurerm_client_config" "current" {}
resource "azurerm_storage_account" "landing" {
  name                            = "st${replace(local.prefix, "-", "")}"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}
resource "azurerm_storage_container" "landing" {
  name                  = "landing"
  storage_account_id    = azurerm_storage_account.landing.id
  container_access_type = "private"
}
resource "azurerm_key_vault" "this" {
  name                          = "kv-${local.prefix}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.this.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = false
}
resource "azurerm_data_factory" "this" {
  name                = "adf-${local.prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  identity { type = "SystemAssigned" }
  managed_virtual_network_enabled = true
}
resource "azurerm_mssql_server" "this" {
  name                          = "sql-${local.prefix}"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  azuread_administrator {
    login_username = var.entra_admin_name
    object_id      = var.entra_admin_object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }
}
resource "azurerm_mssql_database" "warehouse" {
  name                        = "sqldb-erp-dwh"
  server_id                   = azurerm_mssql_server.this.id
  sku_name                    = "GP_S_Gen5_1"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 32
}
