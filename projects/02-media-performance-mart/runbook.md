# Media mart runbook

## Late-arriving correction

1. Land the corrected row with the same natural key and a newer `source_updated_at`.
2. Run `etl.usp_UpsertDailyMetric` with a unique run ID.
3. Confirm `rows_updated` and compare affected KPI dates before publishing.
4. Refresh Power BI only after assertions/reconciliation are green.

## Suspected KPI mismatch

- Confirm grain and filters first.
- Check whether the dashboard used simple average instead of view-weighted retention.
- Verify UTC/date boundaries and source corrections.
- Compare `mart.vw_VideoPerformance` with the inline TVF for the same period.
- Preserve the audit trail; do not silently overwrite run history.

## Periodic upkeep

- Purge successful audit rows only after the agreed retention window; preserve failures longer.
- Review Query Store for regressions after data growth or view changes.
- Update statistics after unusually large backfills.
- Review the covering index against actual Power BI query patterns.
