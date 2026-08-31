# Project 1 — Retail ERP Order-to-Cash Warehouse

## Goal

Build a new SQL Server database for a retail order-to-cash flow and expose trusted finance/operations reporting. This is the larger greenfield project in the portfolio.

## Scope

- Source-like staging for customers, products, order headers and lines.
- Relational operational core plus dimensional reporting layer.
- SCD Type 2 customer history.
- Transactional, retry-safe stored procedures.
- Reject logging, load audit, reconciliation and data-quality assertions.
- Indexes chosen around business keys and reporting access paths.

## Model

```text
stg.Customer --------> dim.Customer (SCD2) ---+
stg.Product  --------> dim.Product -----------+--> fact.SalesOrderLine --> mart.vw_OrderMargin
stg.SalesOrderHeader -------------------------+
stg.SalesOrderLine   -------------------------+
                         |
                         +--> audit.LoadRun / audit.RejectedRow
```

## Run order

Files in `sql/` are intentionally numbered and executed in lexical order. `05_tests.sql` raises an error if any invariant fails.

## Business invariants

- One current dimension row per customer natural key.
- Order numbers are unique and loads are idempotent.
- Quantity and money values cannot be negative.
- Header totals reconcile to fact lines for accepted fixtures.
- Rejected rows remain inspectable instead of disappearing silently.

## Maintenance ownership

The [runbook](runbook.md) covers retry, reconciliation, index/statistics care and safe recovery. This project primarily proves new-build capability; Projects 2 and 3 are the explicit upkeep evidence.
