# Project 3 — SQL Server Reliability Lab

## Goal

Provide a safe, observable maintenance toolkit for an existing SQL Server database. This is the second explicit upkeep project.

## Coverage

- Integrity-check planning with `DBCC CHECKDB`.
- Threshold-based index reorganize/rebuild decisions.
- Statistics refresh planning.
- Backup header/restore verification commands.
- Query Store and DMV diagnostics.
- Data-retention batches instead of one large delete.
- Application locks to prevent overlapping maintenance.
- Dry-run by default and a durable command/outcome log.

## Safety model

Every mutating maintenance procedure defaults to `@execute = 0`. A reviewer can inspect the planned commands before enabling execution. The procedures quote identifiers, exclude tiny indexes, record errors, and release application locks in both success and failure paths.

## What this project does not pretend

The lab does not claim Always On, production on-call, or recovery-time results. Those require a multi-instance environment and measured restore drills. The runbook describes how they would be tested.
