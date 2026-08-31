# MS SQL Server Data Engineering Portfolio

Three reproducible, synthetic-data projects demonstrating database development, maintenance, testing, and operational ownership in Microsoft SQL Server.

> Portfolio status: implemented as independent lab projects in 2026. These are not presented as client engagements or commercial years of experience.

## What a reviewer can verify

| Project | Business scenario | MS SQL development | Maintenance / upkeep | Scale signal |
|---|---|---|---|---|
| [Retail ERP Order-to-Cash](projects/01-retail-erp-warehouse/README.md) | Orders, customers, products, inventory | Greenfield relational model, SCD2, incremental load, stored procedures, views | Idempotent loads, indexes, reconciliation, runbook | Larger new database build |
| [Media Performance Mart](projects/02-media-performance-mart/README.md) | Content reach, revenue, weighted retention | T-SQL ingestion, windowed reporting, inline TVF, KPI views | Late-arriving data handling, audit log, data-quality checks | Production-style analytical mart |
| [SQL Server Reliability Lab](projects/03-sql-server-reliability/README.md) | Operations for an existing transactional database | Diagnostic and maintenance procedures | Integrity, index/statistics care, retention, backup verification, incident runbooks | Repeatable upkeep framework |

Together these provide evidence for:

- three completed MS SQL Server development projects;
- two projects with explicit maintenance and upkeep scope;
- one larger greenfield SQL Server build;
- T-SQL procedures, functions, views, transactions, error handling, indexing and query diagnostics;
- Python-ready ingestion contracts, CI, documentation and data-quality gates.

See [evidence matrix](docs/EVIDENCE_MATRIX.md) for a requirement-by-requirement map, [job-fit analysis](docs/JOB_FIT_AND_GAPS.md) for the supplied vacancies, and [honest positioning](docs/HONEST_POSITIONING.md) for CV/interview wording.

The [GitHub portfolio strategy](docs/GITHUB_PORTFOLIO_STRATEGY.md) explains why this repository stays separate from the existing `de-lab` learning roadmap.

## Architecture

```text
synthetic source data
        |
        v
 staging schemas -> validated T-SQL procedures -> core dimensional/relational models
        |                                         |
        +------------ audit + rejects ------------+
                                                  |
                                                  v
                                      reporting views / data marts
                                                  |
                                                  v
                                  data-quality and operational checks
```

## Run the complete portfolio

Prerequisites: Docker Desktop with Linux containers and Docker Compose.

```bash
cp .env.example .env
docker compose up -d
bash scripts/wait-for-sql.sh
bash scripts/run-all.sh
```

On PowerShell:

```powershell
Copy-Item .env.example .env
docker compose up -d
./scripts/run-all.ps1
```

The scripts create three isolated databases and run their automated assertions. No external or proprietary data is used.

## Repository structure

```text
projects/
  01-retail-erp-warehouse/      # larger greenfield build
  02-media-performance-mart/    # analytical development + upkeep
  03-sql-server-reliability/    # maintenance and incident response
docs/
  EVIDENCE_MATRIX.md
  HONEST_POSITIONING.md
  INTERVIEW_STORIES.md
scripts/
.github/workflows/
```

## Design principles

- Idempotent setup and deterministic synthetic fixtures.
- `TRY/CATCH`, explicit transactions, `XACT_ABORT`, and audit logging around writes.
- Set-based T-SQL; no row-by-row business processing.
- Constraints and tests encode business invariants.
- Operational procedures use dry-run defaults where a change could be risky.
- Every claim in the recruiter-facing documentation links to inspectable code.

## Current verification status

Repository structure and static contracts are checked locally by `scripts/static-check.ps1`. Runtime SQL assertions are defined for Docker/CI and should be considered verified only after the workflow is green on GitHub or `run-all` succeeds locally.
