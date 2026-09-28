# Azure ERP/DWH infrastructure

Creates a disposable development boundary: private Blob landing container, Key Vault, system-assigned ADF identity, serverless Azure SQL and a resource group.

It intentionally does **not** create ADF credentials or put SQL passwords in state as an application secret. Before a real run, add least-privilege ADF roles and secured linked services through an approved deployment workflow. This module has not been applied to Azure yet.
