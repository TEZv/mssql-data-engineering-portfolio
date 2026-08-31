USE RetailERPPortfolio;
GO

CREATE OR ALTER PROCEDURE etl.usp_ReconcileBatch
    @batch_id uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;

    SELECT h.order_number,
           h.stated_total,
           SUM(CASE WHEN l.quantity > 0 AND l.unit_price >= 0 AND l.quantity * l.unit_price >= l.discount_amount
                    THEN l.quantity * l.unit_price - l.discount_amount ELSE 0 END) AS accepted_source_total,
           SUM(COALESCE(f.net_amount, 0)) AS warehouse_total,
           h.stated_total - SUM(COALESCE(f.net_amount, 0)) AS variance
    FROM stg.SalesOrderHeader h
    JOIN stg.SalesOrderLine l ON l.batch_id = h.batch_id AND l.order_number = h.order_number
    LEFT JOIN fact.SalesOrderLine f ON f.order_number = l.order_number AND f.line_number = l.line_number
    WHERE h.batch_id = @batch_id
    GROUP BY h.order_number, h.stated_total;
END;
GO
