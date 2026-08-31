# Evidence matrix

This matrix separates demonstrable project evidence from employment history. Dates refer to portfolio implementation, not client delivery.

| Vacancy requirement | Evidence | Status |
|---|---|---|
| At least 3 completed MS SQL development projects | Three isolated databases, each with schema, programmable objects, fixtures, assertions and documentation | Implemented; runtime verification requires green CI/local Docker run |
| At least 2 maintenance/upkeep projects | Media mart late-arrival/reconciliation runbook; Reliability Lab integrity/index/statistics/retention/backup procedures | Implemented |
| At least 1 larger new SQL Server build | Retail ERP warehouse: staging, operational core, dimensions, facts, audit, incremental load and serving layer | Implemented as the larger portfolio build; not claimed as enterprise scale |
| Stored procedures | `etl.usp_LoadSalesOrder`, `etl.usp_UpsertDailyMetric`, `maintenance.usp_IndexCare` and others | Implemented |
| Functions | Weighted retention inline table-valued function | Implemented |
| Views | Order margin and content KPI serving views | Implemented |
| Query analysis and optimization | Purpose-built indexes, Query Store diagnostics, index usage and fragmentation reports | Implemented |
| Testing/debugging | Executable T-SQL assertions use `THROW`; CI stops on error | Implemented |
| Documentation | README, data dictionaries, ADRs/runbooks, interview stories | Implemented |
| Azure / IaC familiarity | Private Azure SQL Database target, networking, diagnostics, variables and CI are defined in Terraform; portable Terraform initialization and validation passed | Implemented + validated; real deployment not yet claimed |
| Python | Existing professional analytics experience; optional ingestion extension planned, not used to inflate this SQL portfolio | Existing skill, outside these fixtures |

## Completion definition used here

A project is labelled “completed” only when it has:

1. a stated business problem and bounded scope;
2. a reproducible schema and synthetic fixtures;
3. executable database logic;
4. automated assertions;
5. an operational or maintenance note;
6. reviewer-facing documentation.

Runtime status remains explicit: a green GitHub Actions run or successful local `scripts/run-all` is the evidence that all integration assertions executed on SQL Server 2022.
