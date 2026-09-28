# Azure ERP → DWH migration case

> Status: deploy-ready independent portfolio case. Infrastructure and pipeline definitions are code-reviewed and CI-validated; no Azure subscription deployment is claimed yet.

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
- managed identity as the intended Data Factory access model; no secret is committed;
- Terraform resource definition, cost/teardown runbook and CI validation.

## Honest boundary

This is synthetic data and an independent implementation. It is not an employer ERP migration, production Azure operation or a claim of continuous on-call ownership. The `apply` step is intentionally deferred until a personal subscription, budget alert and approved time window exist.

## Evidence layout

- [`infra/azure-erp-dwh`](../../infra/azure-erp-dwh): Terraform for Azure Storage, Data Factory, Key Vault and Azure SQL integration boundary.
- [`adf/pipelines`](adf/pipelines): deployable ADF pipeline JSON; replace parameters only through a secured deployment process.
- [`sql`](sql): staging/DWH objects and reconciliation procedure.
- [`docs/RUNBOOK.md`](docs/RUNBOOK.md): plan, deploy, verify and destroy sequence.

## Interview walkthrough

1. Landing keeps raw ERP files immutable and identifies each load by a batch id.
2. ADF copies one parameterised extract into `stg`, then runs the database merge procedure.
3. The procedure validates source versus target counts, writes the audit outcome and fails the batch on a mismatch.
4. Secrets belong in Key Vault; a managed identity gets only the required roles.
5. An alert is based on failed pipeline runs and freshness, not merely on a dashboard turning red.
