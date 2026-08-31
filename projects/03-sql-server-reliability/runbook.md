# SQL Server reliability runbook

## Weekly maintenance window

1. Confirm the latest successful full/differential/log backups and free disk space.
2. Run integrity and index procedures in dry-run mode.
3. Review candidates, page counts, blocking risk and the maintenance window.
4. Execute approved operations; monitor log growth, blocking and duration.
5. Review `maintenance.OperationLog` and Query Store for regressions.

## Slow-query incident

1. Capture the time window, query text/ID, duration, CPU, reads and waits.
2. Check blocking and parameter sensitivity before changing indexes.
3. Compare Query Store plans and runtime statistics.
4. Reproduce with representative parameters and capture the actual plan.
5. Apply the smallest reversible change; measure before/after.
6. Roll back if resource use or business latency regresses.

## Suspected corruption

- Stop making speculative repairs.
- Preserve logs and identify affected databases/pages with `DBCC CHECKDB` output.
- Validate backups on another instance.
- Prefer restore/page restore according to the recovery design.
- Use repair options only with explicit data-loss acceptance and a tested copy.

## Restore drill

At least quarterly in a real environment: restore the latest chain to an isolated instance, run `DBCC CHECKDB`, validate critical row counts and application smoke tests, and record measured RPO/RTO. A backup is not proven until restored.
