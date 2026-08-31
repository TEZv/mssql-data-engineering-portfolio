output "resource_group_name" {
  description = "Disposable resource group containing the portfolio environment."
  value       = azurerm_resource_group.portfolio.name
}

output "sql_server_name" {
  description = "Azure SQL logical server name."
  value       = azurerm_mssql_server.portfolio.name
}

output "database_name" {
  description = "Portfolio database name."
  value       = azurerm_mssql_database.portfolio.name
}

output "private_endpoint_ip" {
  description = "Private IP used by the SQL private endpoint."
  value       = azurerm_private_endpoint.sql.private_service_connection[0].private_ip_address
}
