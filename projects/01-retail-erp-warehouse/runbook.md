# Retail ERP runbook

## Daily load

1. Land one bounded batch into `stg` tables.
2. Start an `audit.LoadRun` row.
3. Execute dimension procedures before facts.
4. Reconcile source accepted totals to the fact table.
5. Mark the load succeeded only after assertions pass.

## Retry

Loads use stable source keys and update-or-insert semantics. A failed batch can be retried with the same `batch_id`; duplicate order facts are prevented by unique constraints. Investigate `audit.RejectedRow` before closing the incident.

## Recovery

- Stop downstream reporting refresh if reconciliation fails.
- Preserve the failed staging batch and audit record.
- Correct mapping/data rules in a new change, never edit historical facts manually without a ticketed correction procedure.
- Re-run tests, then release downstream refresh.

## Performance care

- Review actual execution plans for the slow query and verify cardinality estimates.
- Update statistics after material data-shape changes.
- Rebuild/reorganize only based on page count, fragmentation and measured workload impact.
- Add indexes only when Query Store/DMV evidence supports the access path; record write-cost trade-offs.
