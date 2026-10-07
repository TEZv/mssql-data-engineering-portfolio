# Azure ERP → DWH migration case

> Status: implemented independent portfolio case, prepared for a controlled Azure trial. Terraform validates locally. Python source/ADF contract tests pass locally; SQL integration tests run in the linked Actions workflow. Azure apply, connector authentication, private-endpoint approval and alert delivery require a live subscription run.

## Goal

Move small synthetic ERP extracts from Azure Blob Storage into an Azure SQL warehouse with an auditable, replay-safe ingestion path.

```text
ERP CSV extracts → Blob /landing → ADF Copy → Azure SQL stg → T-SQL merge → DWH
                                      |                         |
                                      +---- pipeline logs -------+---- reconciliation
```

## What this demonstrates

- a minimal Azure landing, orchestration, secret and warehouse boundary;
- Azure Data Factory pipeline definition with landing-to-staging copy and a stored-procedure step;
- Azure SQL dimensional loading, source-count reconciliation and an audit record;
- managed-identity linked services for Blob and SQL, a private managed integration runtime, scoped Blob reader access, and a SQL bootstrap grant script;
- Terraform resource definition, cost/teardown runbook and CI validation.

## Honest boundary

This is synthetic data and an independent implementation. It is not an employer ERP migration, production Azure operation or a claim of continuous on-call ownership. The `apply` step is intentionally deferred until a personal subscription, budget alert and approved time window exist.

## Evidence layout

- [`infra/azure-erp-dwh`](../../infra/azure-erp-dwh): Terraform for Azure Storage, Data Factory, Key Vault and Azure SQL integration boundary.
- [`adf/pipelines`](adf/pipelines): deployable ADF pipeline JSON; replace parameters only through a secured deployment process.
- [`sql/001_warehouse_load.sql`](sql/001_warehouse_load.sql): staging, three dimensions, sales fact, version-aware load and reconciliation.
- [`sql/002_assertions.sql`](sql/002_assertions.sql): replay, correction, stale version, conflict and rejected-batch assertions, run only in the disposable CI database.
- [`fixtures`](fixtures) and [`scripts/validate_extract.py`](scripts/validate_extract.py): small ERP examples and an independent source manifest.
- [`docs/RUNBOOK.md`](docs/RUNBOOK.md): plan, deploy, verify and destroy sequence.

## Interview walkthrough

1. Landing keeps raw ERP files immutable and identifies each load by a batch id.
2. ADF adds the batch id to the CSV rows and upserts staging on `(BatchId, SourceOrderId)`, then runs the database load procedure.
3. The procedure validates source versus target counts, writes the audit outcome and fails the batch on a mismatch.
4. Blob and SQL use managed identity. Key Vault is provisioned with a linked service for future ERP credentials; this fixture flow consumes no secret. The bootstrap administrator password is sensitive but still enters Terraform state, which must be protected.
5. ADF failure metrics have an alert rule. An optional email must be supplied privately for notification delivery. Freshness is currently a documented SQL check, not a scheduled cloud alert.

## Warehouse contract

Grain: one fact per ERP order (`SourceOrderId`) with one product per order in this fixture. Real multi-line ERP orders need an order-line key. Customer/product dimensions are code lookups (no descriptive history); date is populated from encountered source dates.

Higher `SourceVersion` replaces the current fact; lower versions are audited as stale; equal-version changed payloads fail. Replaying a completed batch leaves the fact/audit unchanged. The source file must stay immutable under its batch id; a sorted staging content hash detects changed completed batches. Source row count and amount are calculated independently in Python, not copied from the staging count. These totals are reconciliation controls, not a proof of complete source-system CDC or deletions.

```powershell
python projects/04-azure-erp-dwh-migration/scripts/validate_extract.py projects/04-azure-erp-dwh-migration/fixtures/initial.csv --batch-id 00000000-0000-0000-0000-000000000001
```

Expected initial manifest: 2 rows, amount 180.00. After the correction fixture, the warehouse has 3 orders, quantity 24 and amount 240.00.

The old audit-only scaffold is replaced. Bootstrap a fresh lab database; upgrading an already deployed older schema would require an explicit ALTER migration.
