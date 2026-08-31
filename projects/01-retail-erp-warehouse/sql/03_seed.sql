USE RetailERPPortfolio;
GO

DECLARE @batch uniqueidentifier = '11111111-1111-1111-1111-111111111111';

INSERT audit.LoadRun(pipeline_name, batch_id, status) VALUES ('retail_order', @batch, 'RUNNING');

INSERT stg.Customer(batch_id, customer_code, customer_name, country_code, segment, source_updated_at) VALUES
(@batch, 'C001', N'Northwind Market', 'PL', 'SMB', '2026-08-01'),
(@batch, 'C002', N'Baltic Retail', 'DE', 'ENTERPRISE', '2026-08-01');

INSERT stg.Product(product_code, product_name, category, standard_cost) VALUES
('P100', N'Organic Shampoo', N'Beauty', 14.0000),
('P200', N'Vitamin Pack', N'Health', 20.0000);

INSERT stg.SalesOrderHeader(batch_id, order_number, customer_code, order_date, currency_code, stated_total) VALUES
(@batch, 'SO-1001', 'C001', '2026-08-15', 'PLN', 100.0000),
(@batch, 'SO-1002', 'C002', '2026-08-16', 'EUR', 60.0000);

INSERT stg.SalesOrderLine(batch_id, order_number, line_number, product_code, quantity, unit_price, discount_amount) VALUES
(@batch, 'SO-1001', 1, 'P100', 2, 30.0000, 5.0000),
(@batch, 'SO-1001', 2, 'P200', 1, 45.0000, 0.0000),
(@batch, 'SO-1002', 1, 'P200', 2, 30.0000, 0.0000),
(@batch, 'SO-1002', 2, 'P100', 0, 30.0000, 0.0000);

EXEC etl.usp_LoadCustomerDimension @batch;
EXEC etl.usp_LoadProductDimension;
EXEC etl.usp_LoadSalesOrder @batch;

-- A later customer change proves that historical facts keep the original dimension version.
DECLARE @customer_change uniqueidentifier = '11111111-1111-1111-1111-111111111112';
INSERT stg.Customer(batch_id, customer_code, customer_name, country_code, segment, source_updated_at) VALUES
(@customer_change, 'C001', N'Northwind Market', 'PL', 'MID_MARKET', '2026-08-20');
EXEC etl.usp_LoadCustomerDimension @customer_change;
GO
