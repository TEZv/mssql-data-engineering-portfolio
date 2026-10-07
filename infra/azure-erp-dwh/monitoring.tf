resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.1
}
resource "azurerm_monitor_diagnostic_setting" "adf" {
  name                       = "adf-runs"
  target_resource_id         = azurerm_data_factory.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  enabled_log { category = "PipelineRuns" }
  enabled_log { category = "ActivityRuns" }
}
resource "azurerm_monitor_action_group" "lab" {
  name                = "ag-${local.prefix}"
  resource_group_name = azurerm_resource_group.this.name
  short_name          = "erpdwhlab"
  dynamic "email_receiver" {
    for_each = var.alert_email == null ? [] : [var.alert_email]
    content {
      name                    = "lab-owner"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}
resource "azurerm_monitor_metric_alert" "failed_pipeline" {
  name                = "alert-${local.prefix}-failed-pipeline"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_data_factory.this.id]
  description         = "Failed ADF pipeline; inspect ActivityRuns then source manifest."
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  criteria {
    metric_namespace = "Microsoft.DataFactory/factories"
    metric_name      = "PipelineFailedRuns"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0
  }
  action { action_group_id = azurerm_monitor_action_group.lab.id }
}
