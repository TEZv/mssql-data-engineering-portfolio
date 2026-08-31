# Interview stories

Use these as technical walkthroughs, not memorized claims. Replace outcomes with measured results only after running benchmarks.

## 1. Greenfield retail ERP warehouse

**Situation:** Orders arrived from an ERP-like source, but finance and operations needed consistent order, margin and fulfillment reporting.

**Task:** Design a SQL Server database that preserved customer history, rejected invalid data, supported repeatable loads and exposed stable reporting contracts.

**Action:** I separated staging, core, dimensional and audit schemas; used SCD Type 2 for customer attributes; wrapped order loads in `XACT_ABORT` plus `TRY/CATCH`; added natural-key idempotency, constraints, indexes, reconciliation checks and a margin view.

**Result:** The repository can rebuild the database from zero and asserts historical correctness, financial reconciliation and idempotent behavior.

**Trade-off:** For a larger production workload I would partition the fact table by order date, use controlled batch sizes, and measure columnstore versus rowstore rather than assume one is faster.

## 2. Media performance mart

**Situation:** Daily content metrics can arrive late or be corrected, while stakeholders need consistent reach, revenue and retention KPIs.

**Task:** Make ingestion repeatable and prevent mathematically incorrect averaging of retention percentages.

**Action:** I created a unique business key for daily facts, implemented transactional upsert logic, logged every run, and calculated retention as a view-weighted measure. Window functions produce rolling performance without duplicating business logic in BI.

**Result:** Re-running a batch updates the intended record instead of duplicating it, and assertions prove weighted retention and KPI grain.

## 3. Reliability and maintenance

**Situation:** An existing database needs predictable upkeep without risky blanket rebuilds.

**Task:** Build safe, observable routines for integrity, indexes, statistics, backups, retention and troubleshooting.

**Action:** Maintenance defaults to dry-run, logs commands and outcomes, serializes runs with application locks, and distinguishes reorganize from rebuild thresholds. Diagnostic queries read Query Store and DMVs; runbooks define rollback/escalation steps.

**Result:** Operations are reviewable before execution and failures are captured with enough context to investigate.

## Questions to expect

- Why SCD2 here, and where would current-state overwrite be sufficient?
- How does the load behave after a retry halfway through?
- Why use an inline TVF instead of a scalar function?
- When should an index not be rebuilt despite high fragmentation?
- What differs between SQL Server, Azure SQL Database and Managed Instance for jobs/backups?
- How would you prove an optimization instead of relying on intuition?
