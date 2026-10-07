locals {
  adf_root = "${path.module}/../../projects/04-azure-erp-dwh-migration/adf"
  linked_services = {
    for filename in fileset("${path.module}/../../projects/04-azure-erp-dwh-migration/adf/linkedServices", "*.json") :
    trimsuffix(filename, ".json") => jsondecode(templatefile("${path.module}/../../projects/04-azure-erp-dwh-migration/adf/linkedServices/${filename}", {
      blob_endpoint = azurerm_storage_account.landing.primary_blob_endpoint
      sql_fqdn      = azurerm_mssql_server.this.fully_qualified_domain_name
      database_name = azurerm_mssql_database.warehouse.name
      vault_uri     = azurerm_key_vault.this.vault_uri
    })).properties
  }
  datasets = { for filename in fileset("${local.adf_root}/datasets", "*.json") : trimsuffix(filename, ".json") => jsondecode(file("${local.adf_root}/datasets/${filename}")).properties }
  pipeline = jsondecode(file("${local.adf_root}/pipelines/pl_erp_to_dwh.json")).properties
}
resource "azurerm_data_factory_integration_runtime_azure" "private" {
  name                    = "ir-private"
  data_factory_id         = azurerm_data_factory.this.id
  location                = var.location
  virtual_network_enabled = true
}
resource "azurerm_data_factory_managed_private_endpoint" "sql" {
  name               = "mpe-sql"
  data_factory_id    = azurerm_data_factory.this.id
  target_resource_id = azurerm_mssql_server.this.id
  subresource_name   = "sqlServer"
  depends_on         = [azurerm_data_factory_integration_runtime_azure.private]
}
resource "azurerm_data_factory_managed_private_endpoint" "blob" {
  name               = "mpe-blob"
  data_factory_id    = azurerm_data_factory.this.id
  target_resource_id = azurerm_storage_account.landing.id
  subresource_name   = "blob"
  depends_on         = [azurerm_data_factory_integration_runtime_azure.private]
}
resource "azurerm_data_factory_managed_private_endpoint" "vault" {
  name               = "mpe-vault"
  data_factory_id    = azurerm_data_factory.this.id
  target_resource_id = azurerm_key_vault.this.id
  subresource_name   = "vault"
  depends_on         = [azurerm_data_factory_integration_runtime_azure.private]
}
resource "azurerm_role_assignment" "adf_blob" {
  scope                = azurerm_storage_container.landing.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_data_factory.this.identity[0].principal_id
}
resource "azurerm_role_assignment" "adf_vault" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_data_factory.this.identity[0].principal_id
}
resource "azurerm_data_factory_linked_custom_service" "this" {
  for_each             = local.linked_services
  name                 = each.key
  data_factory_id      = azurerm_data_factory.this.id
  type                 = each.value.type
  type_properties_json = jsonencode(each.value.typeProperties)
  integration_runtime { name = azurerm_data_factory_integration_runtime_azure.private.name }
}
resource "azurerm_data_factory_custom_dataset" "this" {
  for_each             = local.datasets
  name                 = each.key
  data_factory_id      = azurerm_data_factory.this.id
  type                 = each.value.type
  type_properties_json = jsonencode(each.value.typeProperties)
  parameters           = { for name, value in try(each.value.parameters, {}) : name => "" }
  schema_json          = jsonencode(each.value.schema)
  linked_service { name = azurerm_data_factory_linked_custom_service.this[each.value.linkedServiceName.referenceName].name }
}
resource "azurerm_data_factory_pipeline" "erp" {
  name            = "pl_erp_to_dwh"
  data_factory_id = azurerm_data_factory.this.id
  parameters      = { for name, value in local.pipeline.parameters : name => "" }
  activities_json = jsonencode(local.pipeline.activities)
  concurrency     = 1
  depends_on      = [azurerm_data_factory_custom_dataset.this]
}
