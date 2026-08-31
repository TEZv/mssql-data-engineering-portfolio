locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    environment = var.environment
    managed_by  = "terraform"
    purpose     = "independent-data-engineering-portfolio"
  })
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "portfolio" {
  name     = "rg-${local.name_prefix}-${random_string.suffix.result}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "portfolio" {
  name                = "vnet-${local.name_prefix}"
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name
  address_space       = ["10.42.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.portfolio.name
  virtual_network_name = azurerm_virtual_network.portfolio.name
  address_prefixes     = ["10.42.10.0/24"]
}

resource "azurerm_mssql_server" "portfolio" {
  name                          = "sql-${local.name_prefix}-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.portfolio.name
  location                      = azurerm_resource_group.portfolio.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = local.common_tags
}

resource "azurerm_mssql_database" "portfolio" {
  name                        = "sqldb-portfolio"
  server_id                   = azurerm_mssql_server.portfolio.id
  sku_name                    = "GP_S_Gen5_1"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 32
  zone_redundant              = false
  storage_account_type        = "Local"
  tags                        = local.common_tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.portfolio.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "sql-private-dns-link"
  resource_group_name   = azurerm_resource_group.portfolio.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.portfolio.id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-${local.name_prefix}-sql"
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-${local.name_prefix}-sql"
    private_connection_resource_id = azurerm_mssql_server.portfolio.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-private-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

resource "azurerm_log_analytics_workspace" "portfolio" {
  name                = "log-${local.name_prefix}-${random_string.suffix.result}"
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

data "azurerm_monitor_diagnostic_categories" "database" {
  resource_id = azurerm_mssql_database.portfolio.id
}

resource "azurerm_monitor_diagnostic_setting" "database" {
  name                       = "diag-sql-database"
  target_resource_id         = azurerm_mssql_database.portfolio.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.portfolio.id

  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.database.log_category_types)
    content {
      category = enabled_log.value
    }
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
