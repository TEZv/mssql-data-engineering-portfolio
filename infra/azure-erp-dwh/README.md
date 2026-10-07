# Azure ERP/DWH infrastructure

Creates a disposable development boundary: private Blob landing container, Key Vault, system-assigned ADF identity, serverless Azure SQL, managed ADF private endpoints, linked services/datasets/pipeline, scoped Blob/Key Vault RBAC, run logs and failure alert.

SQL data-plane access is bootstrapped with the checked-in SQL grant template; Azure resource RBAC alone does not create a database user. SQL and Key Vault public network access are disabled. Approve the managed private endpoints before connection tests. Blob is authenticated but has a public endpoint for the initial upload; it is not a fully network-isolated storage account.

No application secret is required for Blob/SQL managed identity. The SQL administrator password **does enter Terraform state**, even though marked sensitive. Use restricted encrypted state storage before apply. The Key Vault linked service is prepared but unused by this fixture pipeline.

Required input: subscription_id, sql_admin_password, entra_admin_name, entra_admin_object_id. Optional alert_email adds a notification recipient; without it the rule is visible in Azure Monitor but delivers no email. This module has not been applied to Azure.
