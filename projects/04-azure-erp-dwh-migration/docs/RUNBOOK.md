# Controlled deployment runbook

## Before any Azure apply

1. Use a personal Azure subscription only; never an employer subscription.
2. Create a budget alert and set a small hard review threshold before deploying.
3. Use a new resource group in a disposable `dev` environment.
4. Authenticate through Azure Portal or Cloud Shell. Do not store credentials in Git or a `.tfvars` file.

## Deploy sequence

1. `terraform fmt -check -recursive`, `terraform init -backend=false`, then `terraform validate`.
2. Supply the subscription id only in the current shell/session and review `terraform plan` line by line.
3. Apply the infrastructure module; give the ADF managed identity only the storage and database permissions documented in the Terraform outputs.
4. Deploy linked services/datasets first, then `pl_erp_to_dwh.json` with ARM/Bicep or the ADF publish process.
5. Upload only the included synthetic ERP file, run a new batch id, and retain the pipeline-run link.

## Verification

- ADF Copy activity has a successful row count.
- Stored procedure finishes successfully and writes one `etl.BatchAudit` row.
- Re-running the same batch must be rejected by the staging primary key or explicitly investigated; do not silently double-count.
- Capture no screenshots containing subscription ids, connection strings or personal data.

## Teardown

After evidence is captured, review the resource group and run `terraform destroy`. Confirm the resource group is empty and check Cost Management again the next day.
