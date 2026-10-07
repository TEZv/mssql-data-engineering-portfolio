# Controlled deployment runbook

## Before any Azure apply

1. Use a personal Azure subscription only; never an employer subscription.
2. Create a small budget alert before deploying. A budget alert is not a hard spending cap; inspect trial spending protection separately. Do not activate the trial until code and a short test session are ready.
3. Use a new resource group in a disposable `dev` environment.
4. Authenticate through Azure Portal or Cloud Shell. Do not store credentials in Git. Supply private values through the shell or an ignored local file. Protect Terraform state: it includes the SQL administrator password.

## Deploy sequence

1. `terraform fmt -check -recursive`, `terraform init -backend=false`, then `terraform validate`.
2. Supply the subscription id only in the current shell/session and review `terraform plan` line by line.
3. Apply `infra/azure-erp-dwh`. Terraform creates the linked services, datasets and pipeline as well as infrastructure. The apply needs permission to create role assignments. Required variables include an Entra SQL administrator group name and object id.
4. In each SQL/Blob/Key Vault resource, inspect the ADF managed-private-endpoint request and approve the matching factory connection. A created endpoint is not automatically an approved connection. Test Blob and SQL linked services in ADF.
5. Bootstrap SQL from a client with network connectivity. Cloud Shell alone cannot reach a private SQL server. Use an authorised private-network client, or temporarily allow only your exact client IP through the Azure SQL firewall, enable public access for bootstrap, run `001_warehouse_load.sql` in the new database and the rendered `bootstrap_adf.sql.template` as the Entra administrator, then remove that firewall rule and disable public access. Record that temporary exception; do not use an allow-all-Azure-services rule. An administrator lacking directory lookup permission may need identity lookup configured for CREATE USER; resolve this in the live run.
6. Give the uploading user scoped Storage Blob Data Contributor access (ADF already has scoped reader access). Upload `fixtures/initial.csv` into `landing` using Entra authentication. Preserve the file under its batch id; do not overwrite it. Revoke temporary upload access after the test if no longer needed.
7. Run the Python manifest tool. Use its `parameters` object for `az datafactory pipeline create-run --resource-group <rg> --factory-name <factory> --name pl_erp_to_dwh --parameters @parameters.json`. The wrapper output also includes a SHA256; extract only the parameters object for this command. Use unique batch ids for initial and correction.
8. Run initial, identical replay, then correction. Save run ids, activity output counts and the fact/audit query results. Expected final fact count is 3, quantity 24, amount 240.00. Save redacted evidence only.

## Verification

- ADF Copy activity has a successful row count.
- Stored procedure finishes successfully and writes one `etl.BatchAudit` row.
- Re-running the same immutable batch must succeed without duplicate facts or audit rows. Copy upsert handles staging retries; the SQL load handles completed-batch retries.
- Capture no screenshots containing subscription ids, connection strings or personal data.

## Teardown

After evidence is captured, review the resource group and run `terraform destroy`. Confirm the resource group is empty and check Cost Management again the next day.

Key Vault soft deletion can retain a recoverable vault for seven days. Record that recovery state rather than claiming every resource record instantly disappears. Never run the SQL assertion fixture against the deployed cloud database: the test runner recreates only the local/CI database `AzureErpDwhLab`.

## Failure drill and freshness

Pass an incorrect expected_rows value; the database should throw, the ADF run should fail, and no batch audit/fact mutation should appear. Inspect ActivityRuns and the failed-run metric alert. An email recipient must be supplied for alert delivery; capture that notification only in private evidence.

```sql
SELECT MAX(CheckedAt) LastSuccessfulBatch,
       DATEDIFF(minute,MAX(CheckedAt),SYSUTCDATETIME()) MinutesSinceSuccess
FROM etl.BatchAudit;
```

A missing batch and a failed run are different conditions. There is no automatic daily schedule in this case: a recurring freshness alert is a future operational extension after a schedule/SLA is agreed.
