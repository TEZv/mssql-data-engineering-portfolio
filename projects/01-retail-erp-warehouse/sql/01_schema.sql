USE RetailERPPortfolio;
GO

DROP VIEW IF EXISTS mart.vw_OrderMargin;
DROP TABLE IF EXISTS fact.SalesOrderLine;
DROP TABLE IF EXISTS dim.Product;
DROP TABLE IF EXISTS dim.Customer;
DROP TABLE IF EXISTS stg.SalesOrderLine;
DROP TABLE IF EXISTS stg.SalesOrderHeader;
DROP TABLE IF EXISTS stg.Product;
DROP TABLE IF EXISTS stg.Customer;
DROP TABLE IF EXISTS audit.RejectedRow;
DROP TABLE IF EXISTS audit.LoadRun;
GO

CREATE TABLE audit.LoadRun (
    load_run_id bigint IDENTITY(1,1) CONSTRAINT PK_LoadRun PRIMARY KEY,
    pipeline_name sysname NOT NULL,
    batch_id uniqueidentifier NOT NULL,
    started_at datetime2(3) NOT NULL CONSTRAINT DF_LoadRun_started DEFAULT SYSUTCDATETIME(),
    completed_at datetime2(3) NULL,
    status varchar(12) NOT NULL CONSTRAINT CK_LoadRun_status CHECK (status IN ('RUNNING','SUCCEEDED','FAILED')),
    rows_inserted int NOT NULL CONSTRAINT DF_LoadRun_inserted DEFAULT 0,
    rows_updated int NOT NULL CONSTRAINT DF_LoadRun_updated DEFAULT 0,
    error_message nvarchar(2048) NULL,
    CONSTRAINT UQ_LoadRun_batch UNIQUE (pipeline_name, batch_id)
);

CREATE TABLE audit.RejectedRow (
    rejected_row_id bigint IDENTITY(1,1) CONSTRAINT PK_RejectedRow PRIMARY KEY,
    load_run_id bigint NOT NULL CONSTRAINT FK_RejectedRow_LoadRun REFERENCES audit.LoadRun(load_run_id),
    source_entity sysname NOT NULL,
    source_key nvarchar(200) NULL,
    reason_code varchar(50) NOT NULL,
    payload nvarchar(max) NULL,
    rejected_at datetime2(3) NOT NULL CONSTRAINT DF_RejectedRow_at DEFAULT SYSUTCDATETIME()
);

CREATE TABLE stg.Customer (
    batch_id uniqueidentifier NOT NULL,
    customer_code varchar(30) NOT NULL,
    customer_name nvarchar(200) NULL,
    country_code char(2) NULL,
    segment varchar(30) NULL,
    source_updated_at datetime2(3) NOT NULL
);

CREATE TABLE stg.Product (
    product_code varchar(30) NOT NULL,
    product_name nvarchar(200) NOT NULL,
    category nvarchar(100) NOT NULL,
    standard_cost decimal(19,4) NOT NULL
);

CREATE TABLE stg.SalesOrderHeader (
    batch_id uniqueidentifier NOT NULL,
    order_number varchar(30) NOT NULL,
    customer_code varchar(30) NOT NULL,
    order_date date NOT NULL,
    currency_code char(3) NOT NULL,
    stated_total decimal(19,4) NOT NULL
);

CREATE TABLE stg.SalesOrderLine (
    batch_id uniqueidentifier NOT NULL,
    order_number varchar(30) NOT NULL,
    line_number smallint NOT NULL,
    product_code varchar(30) NOT NULL,
    quantity int NOT NULL,
    unit_price decimal(19,4) NOT NULL,
    discount_amount decimal(19,4) NOT NULL
);

CREATE TABLE dim.Customer (
    customer_key int IDENTITY(1,1) CONSTRAINT PK_dim_Customer PRIMARY KEY,
    customer_code varchar(30) NOT NULL,
    customer_name nvarchar(200) NOT NULL,
    country_code char(2) NOT NULL,
    segment varchar(30) NOT NULL,
    valid_from datetime2(3) NOT NULL,
    valid_to datetime2(3) NOT NULL,
    is_current bit NOT NULL,
    row_hash varbinary(32) NOT NULL,
    CONSTRAINT CK_dim_Customer_dates CHECK (valid_from < valid_to)
);
CREATE UNIQUE INDEX UX_dim_Customer_current ON dim.Customer(customer_code) WHERE is_current = 1;
CREATE INDEX IX_dim_Customer_history ON dim.Customer(customer_code, valid_from, valid_to);

CREATE TABLE dim.Product (
    product_key int IDENTITY(1,1) CONSTRAINT PK_dim_Product PRIMARY KEY,
    product_code varchar(30) NOT NULL CONSTRAINT UQ_dim_Product_code UNIQUE,
    product_name nvarchar(200) NOT NULL,
    category nvarchar(100) NOT NULL,
    standard_cost decimal(19,4) NOT NULL CONSTRAINT CK_dim_Product_cost CHECK (standard_cost >= 0)
);

CREATE TABLE fact.SalesOrderLine (
    sales_order_line_key bigint IDENTITY(1,1) CONSTRAINT PK_fact_SalesOrderLine PRIMARY KEY,
    order_number varchar(30) NOT NULL,
    line_number smallint NOT NULL,
    order_date date NOT NULL,
    customer_key int NOT NULL CONSTRAINT FK_fact_Customer REFERENCES dim.Customer(customer_key),
    product_key int NOT NULL CONSTRAINT FK_fact_Product REFERENCES dim.Product(product_key),
    currency_code char(3) NOT NULL,
    quantity int NOT NULL CONSTRAINT CK_fact_quantity CHECK (quantity > 0),
    unit_price decimal(19,4) NOT NULL CONSTRAINT CK_fact_price CHECK (unit_price >= 0),
    discount_amount decimal(19,4) NOT NULL CONSTRAINT CK_fact_discount CHECK (discount_amount >= 0),
    net_amount AS CONVERT(decimal(19,4), quantity * unit_price - discount_amount) PERSISTED,
    loaded_at datetime2(3) NOT NULL CONSTRAINT DF_fact_loaded DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_fact_order_line UNIQUE (order_number, line_number),
    CONSTRAINT CK_fact_net CHECK (quantity * unit_price >= discount_amount)
);
CREATE INDEX IX_fact_order_date ON fact.SalesOrderLine(order_date) INCLUDE (customer_key, product_key, net_amount);
GO
