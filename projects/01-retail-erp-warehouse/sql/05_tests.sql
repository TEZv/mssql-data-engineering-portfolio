USE RetailERPPortfolio;
GO

IF (SELECT COUNT(*) FROM fact.SalesOrderLine) <> 3
    THROW 51001, 'Expected exactly three accepted sales-order lines.', 1;

IF (SELECT COUNT(*) FROM audit.RejectedRow WHERE reason_code = 'INVALID_MEASURE') <> 1
    THROW 51002, 'Expected one rejected invalid line.', 1;

IF EXISTS (
    SELECT customer_code FROM dim.Customer WHERE is_current = 1 GROUP BY customer_code HAVING COUNT(*) > 1
)
    THROW 51003, 'SCD2 invariant failed: multiple current customer versions.', 1;

IF (SELECT COUNT(*) FROM dim.Customer WHERE customer_code = 'C001') <> 2
   OR NOT EXISTS (SELECT 1 FROM dim.Customer WHERE customer_code = 'C001' AND segment = 'MID_MARKET' AND is_current = 1)
    THROW 51007, 'SCD2 history or current-version switch failed.', 1;

IF (SELECT SUM(net_amount) FROM fact.SalesOrderLine) <> 160.0000
    THROW 51004, 'Revenue reconciliation failed.', 1;

DECLARE @batch uniqueidentifier = '11111111-1111-1111-1111-111111111111';
EXEC etl.usp_LoadSalesOrder @batch;
IF (SELECT COUNT(*) FROM fact.SalesOrderLine) <> 3
    THROW 51005, 'Idempotency failed on retry.', 1;

IF NOT EXISTS (SELECT 1 FROM mart.vw_OrderMargin WHERE order_number = 'SO-1001' AND category = N'Beauty' AND gross_margin = 27.0000)
    THROW 51006, 'Margin view returned an unexpected result.', 1;

PRINT 'Retail ERP assertions passed.';
GO
