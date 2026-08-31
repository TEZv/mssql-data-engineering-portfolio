USE RetailERPPortfolio;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE etl.usp_LoadCustomerDimension
    @batch_id uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @effective_at datetime2(3) = SYSUTCDATETIME();
    DECLARE @max_date datetime2(3) = '9999-12-31 23:59:59.997';

    BEGIN TRY
        BEGIN TRANSACTION;

        ;WITH valid_source AS (
            SELECT customer_code, customer_name, country_code, segment,
                   HASHBYTES('SHA2_256', CONCAT(customer_name, '|', country_code, '|', segment)) AS row_hash,
                   ROW_NUMBER() OVER (PARTITION BY customer_code ORDER BY source_updated_at DESC) AS rn
            FROM stg.Customer
            WHERE batch_id = @batch_id
              AND customer_name IS NOT NULL
              AND country_code IS NOT NULL
              AND segment IS NOT NULL
        )
        UPDATE target
           SET valid_to = @effective_at, is_current = 0
        FROM dim.Customer target
        JOIN valid_source source ON source.customer_code = target.customer_code AND source.rn = 1
        WHERE target.is_current = 1 AND target.row_hash <> source.row_hash;

        ;WITH valid_source AS (
            SELECT customer_code, customer_name, country_code, segment,
                   HASHBYTES('SHA2_256', CONCAT(customer_name, '|', country_code, '|', segment)) AS row_hash,
                   ROW_NUMBER() OVER (PARTITION BY customer_code ORDER BY source_updated_at DESC) AS rn
            FROM stg.Customer
            WHERE batch_id = @batch_id
              AND customer_name IS NOT NULL
              AND country_code IS NOT NULL
              AND segment IS NOT NULL
        )
        INSERT dim.Customer(customer_code, customer_name, country_code, segment, valid_from, valid_to, is_current, row_hash)
        SELECT s.customer_code, s.customer_name, s.country_code, s.segment, @effective_at, @max_date, 1, s.row_hash
        FROM valid_source s
        LEFT JOIN dim.Customer d ON d.customer_code = s.customer_code AND d.is_current = 1
        WHERE s.rn = 1 AND d.customer_key IS NULL;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE etl.usp_LoadSalesOrder
    @batch_id uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT audit.RejectedRow(load_run_id, source_entity, source_key, reason_code, payload)
        SELECT lr.load_run_id, 'SalesOrderLine', CONCAT(l.order_number, '/', l.line_number), 'INVALID_MEASURE',
               CONCAT('quantity=', l.quantity, ';price=', l.unit_price, ';discount=', l.discount_amount)
        FROM stg.SalesOrderLine l
        CROSS APPLY (SELECT load_run_id FROM audit.LoadRun WHERE pipeline_name = 'retail_order' AND batch_id = @batch_id) lr
        WHERE l.batch_id = @batch_id
          AND (l.quantity <= 0 OR l.unit_price < 0 OR l.discount_amount < 0 OR l.quantity * l.unit_price < l.discount_amount)
          AND NOT EXISTS (
              SELECT 1 FROM audit.RejectedRow r
              WHERE r.load_run_id = lr.load_run_id AND r.source_entity = 'SalesOrderLine'
                AND r.source_key = CONCAT(l.order_number, '/', l.line_number)
          );

        INSERT fact.SalesOrderLine(order_number, line_number, order_date, customer_key, product_key,
                                   currency_code, quantity, unit_price, discount_amount)
        SELECT l.order_number, l.line_number, h.order_date, c.customer_key, p.product_key,
               h.currency_code, l.quantity, l.unit_price, l.discount_amount
        FROM stg.SalesOrderLine l
        JOIN stg.SalesOrderHeader h ON h.batch_id = l.batch_id AND h.order_number = l.order_number
        JOIN dim.Customer c ON c.customer_code = h.customer_code AND c.is_current = 1
        JOIN dim.Product p ON p.product_code = l.product_code
        WHERE l.batch_id = @batch_id
          AND l.quantity > 0 AND l.unit_price >= 0 AND l.discount_amount >= 0
          AND l.quantity * l.unit_price >= l.discount_amount
          AND NOT EXISTS (
              SELECT 1 FROM fact.SalesOrderLine f
              WHERE f.order_number = l.order_number AND f.line_number = l.line_number
          );

        UPDATE audit.LoadRun
           SET completed_at = SYSUTCDATETIME(), status = 'SUCCEEDED', rows_inserted = @@ROWCOUNT
         WHERE pipeline_name = 'retail_order' AND batch_id = @batch_id;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        UPDATE audit.LoadRun SET completed_at = SYSUTCDATETIME(), status = 'FAILED', error_message = ERROR_MESSAGE()
         WHERE pipeline_name = 'retail_order' AND batch_id = @batch_id;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER VIEW mart.vw_OrderMargin
AS
SELECT f.order_number, f.order_date, c.customer_code, c.segment, p.category,
       SUM(f.quantity) AS units,
       SUM(f.net_amount) AS net_revenue,
       SUM(CONVERT(decimal(19,4), f.quantity * p.standard_cost)) AS standard_cost,
       SUM(f.net_amount - CONVERT(decimal(19,4), f.quantity * p.standard_cost)) AS gross_margin
FROM fact.SalesOrderLine f
JOIN dim.Customer c ON c.customer_key = f.customer_key
JOIN dim.Product p ON p.product_key = f.product_key
GROUP BY f.order_number, f.order_date, c.customer_code, c.segment, p.category;
GO
