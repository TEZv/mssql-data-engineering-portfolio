-- Run in the destination database (Azure SQL or the isolated CI database).
IF SCHEMA_ID('stg') IS NULL EXEC('CREATE SCHEMA stg');
IF SCHEMA_ID('etl') IS NULL EXEC('CREATE SCHEMA etl');
IF SCHEMA_ID('dwh') IS NULL EXEC('CREATE SCHEMA dwh');
GO
IF OBJECT_ID('stg.SalesOrder') IS NULL
CREATE TABLE stg.SalesOrder (
 BatchId uniqueidentifier NOT NULL,
 SourceOrderId nvarchar(50) NOT NULL,
 OrderDate date NOT NULL,
 CustomerCode nvarchar(50) NOT NULL,
 ProductCode nvarchar(50) NOT NULL,
 Quantity int NOT NULL,
 NetAmount decimal(18,2) NOT NULL,
 SourceVersion int NOT NULL,
 CONSTRAINT PK_stg_SalesOrder PRIMARY KEY (BatchId, SourceOrderId)
);
IF OBJECT_ID('dwh.DimCustomer') IS NULL
CREATE TABLE dwh.DimCustomer (CustomerKey int IDENTITY PRIMARY KEY, CustomerCode nvarchar(50) NOT NULL UNIQUE);
IF OBJECT_ID('dwh.DimProduct') IS NULL
CREATE TABLE dwh.DimProduct (ProductKey int IDENTITY PRIMARY KEY, ProductCode nvarchar(50) NOT NULL UNIQUE);
IF OBJECT_ID('dwh.DimDate') IS NULL
CREATE TABLE dwh.DimDate (DateKey int PRIMARY KEY, CalendarDate date NOT NULL UNIQUE, CalendarYear smallint NOT NULL, CalendarMonth tinyint NOT NULL);
IF OBJECT_ID('dwh.FactSalesOrder') IS NULL
CREATE TABLE dwh.FactSalesOrder (
 SourceOrderId nvarchar(50) NOT NULL PRIMARY KEY,
 DateKey int NOT NULL REFERENCES dwh.DimDate(DateKey),
 CustomerKey int NOT NULL REFERENCES dwh.DimCustomer(CustomerKey),
 ProductKey int NOT NULL REFERENCES dwh.DimProduct(ProductKey),
 Quantity int NOT NULL CHECK (Quantity > 0),
 NetAmount decimal(18,2) NOT NULL CHECK (NetAmount >= 0),
 SourceVersion int NOT NULL CHECK (SourceVersion > 0),
 LastBatchId uniqueidentifier NOT NULL
);
IF OBJECT_ID('etl.BatchAudit') IS NULL
CREATE TABLE etl.BatchAudit (
 BatchId uniqueidentifier NOT NULL PRIMARY KEY,
 SourceRows int NOT NULL, SourceAmount decimal(18,2) NOT NULL, ContentHash varbinary(32) NOT NULL,
 InsertedRows int NOT NULL, UpdatedRows int NOT NULL, StaleRows int NOT NULL,
 CheckedAt datetime2(3) NOT NULL DEFAULT sysutcdatetime()
);
GO
CREATE OR ALTER PROCEDURE etl.usp_LoadSalesOrderBatch
 @BatchId uniqueidentifier, @ExpectedRows int, @ExpectedAmount decimal(18,2)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @BatchId IS NULL OR @ExpectedRows IS NULL OR @ExpectedAmount IS NULL OR @ExpectedRows<=0
   THROW 51001, 'A non-empty source manifest and batch id are required.', 1;
 DECLARE @rows int, @amount decimal(18,2), @inserted int, @updated int, @stale int, @lock int, @hash varbinary(32);
 BEGIN TRY
  BEGIN TRANSACTION;
  EXEC @lock=sys.sp_getapplock @Resource='erp-dwh-load', @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=10000;
  IF @lock<0 THROW 51002, 'Warehouse load lock unavailable.', 1;
  SELECT @rows=COUNT(*), @amount=COALESCE(SUM(NetAmount),0) FROM stg.SalesOrder WHERE BatchId=@BatchId;
  SELECT @hash=HASHBYTES('SHA2_256',STRING_AGG(CONVERT(nvarchar(max),CONCAT(
    SourceOrderId,'|',CONVERT(char(10),OrderDate,23),'|',CustomerCode,'|',ProductCode,'|',Quantity,'|',NetAmount,'|',SourceVersion)),CHAR(10))
    WITHIN GROUP (ORDER BY SourceOrderId)) FROM stg.SalesOrder WHERE BatchId=@BatchId;
  IF @rows<>@ExpectedRows OR @amount<>@ExpectedAmount THROW 51003, 'Source manifest does not reconcile with staging.', 1;
  IF EXISTS (SELECT 1 FROM stg.SalesOrder WHERE BatchId=@BatchId AND
       (Quantity<=0 OR NetAmount<0 OR SourceVersion<=0 OR LEN(TRIM(CustomerCode))=0 OR LEN(TRIM(ProductCode))=0))
    THROW 51004, 'Invalid ERP values.', 1;
  IF EXISTS (SELECT 1 FROM stg.SalesOrder s JOIN dwh.FactSalesOrder f ON f.SourceOrderId=s.SourceOrderId
     JOIN dwh.DimCustomer c ON c.CustomerKey=f.CustomerKey JOIN dwh.DimProduct p ON p.ProductKey=f.ProductKey
     WHERE s.BatchId=@BatchId AND s.SourceVersion=f.SourceVersion AND
     (s.Quantity<>f.Quantity OR s.NetAmount<>f.NetAmount OR c.CustomerCode<>s.CustomerCode OR
      p.ProductCode<>s.ProductCode OR f.DateKey<>CONVERT(int,CONVERT(char(8),s.OrderDate,112))))
    THROW 51005, 'Equal-version payload conflict: investigate source.', 1;
  IF EXISTS (SELECT 1 FROM etl.BatchAudit WHERE BatchId=@BatchId)
  BEGIN
   IF EXISTS (SELECT 1 FROM etl.BatchAudit WHERE BatchId=@BatchId AND (SourceRows<>@rows OR SourceAmount<>@amount OR ContentHash<>@hash))
     THROW 51006, 'Completed batch manifest changed.', 1;
   COMMIT; RETURN;
  END;
  INSERT dwh.DimCustomer(CustomerCode) SELECT DISTINCT s.CustomerCode FROM stg.SalesOrder s
    WHERE BatchId=@BatchId AND NOT EXISTS (SELECT 1 FROM dwh.DimCustomer c WHERE c.CustomerCode=s.CustomerCode);
  INSERT dwh.DimProduct(ProductCode) SELECT DISTINCT s.ProductCode FROM stg.SalesOrder s
    WHERE BatchId=@BatchId AND NOT EXISTS (SELECT 1 FROM dwh.DimProduct p WHERE p.ProductCode=s.ProductCode);
  INSERT dwh.DimDate(DateKey,CalendarDate,CalendarYear,CalendarMonth)
    SELECT DISTINCT CONVERT(int,CONVERT(char(8),s.OrderDate,112)),s.OrderDate,YEAR(s.OrderDate),MONTH(s.OrderDate)
    FROM stg.SalesOrder s WHERE BatchId=@BatchId AND NOT EXISTS (SELECT 1 FROM dwh.DimDate d WHERE d.CalendarDate=s.OrderDate);
  SELECT @stale=COUNT(*) FROM stg.SalesOrder s JOIN dwh.FactSalesOrder f ON f.SourceOrderId=s.SourceOrderId
    WHERE s.BatchId=@BatchId AND s.SourceVersion<f.SourceVersion;
  UPDATE f SET DateKey=CONVERT(int,CONVERT(char(8),s.OrderDate,112)),CustomerKey=c.CustomerKey,ProductKey=p.ProductKey,
      Quantity=s.Quantity,NetAmount=s.NetAmount,SourceVersion=s.SourceVersion,LastBatchId=@BatchId
    FROM dwh.FactSalesOrder f JOIN stg.SalesOrder s ON s.SourceOrderId=f.SourceOrderId
    JOIN dwh.DimCustomer c ON c.CustomerCode=s.CustomerCode JOIN dwh.DimProduct p ON p.ProductCode=s.ProductCode
    WHERE s.BatchId=@BatchId AND s.SourceVersion>f.SourceVersion;
  SET @updated=@@ROWCOUNT;
  INSERT dwh.FactSalesOrder SELECT s.SourceOrderId,CONVERT(int,CONVERT(char(8),s.OrderDate,112)),c.CustomerKey,p.ProductKey,
      s.Quantity,s.NetAmount,s.SourceVersion,@BatchId FROM stg.SalesOrder s
    JOIN dwh.DimCustomer c ON c.CustomerCode=s.CustomerCode JOIN dwh.DimProduct p ON p.ProductCode=s.ProductCode
    WHERE s.BatchId=@BatchId AND NOT EXISTS (SELECT 1 FROM dwh.FactSalesOrder f WHERE f.SourceOrderId=s.SourceOrderId);
  SET @inserted=@@ROWCOUNT;
  IF EXISTS (SELECT 1 FROM stg.SalesOrder s JOIN dwh.FactSalesOrder f ON f.SourceOrderId=s.SourceOrderId
    WHERE s.BatchId=@BatchId AND s.SourceVersion>=f.SourceVersion AND
       (s.NetAmount<>f.NetAmount OR s.Quantity<>f.Quantity OR s.SourceVersion<>f.SourceVersion))
    THROW 51007, 'Target reconciliation failed.', 1;
  INSERT etl.BatchAudit(BatchId,SourceRows,SourceAmount,ContentHash,InsertedRows,UpdatedRows,StaleRows)
    VALUES(@BatchId,@rows,@amount,@hash,@inserted,@updated,@stale);
  COMMIT;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER VIEW dwh.vwDailySales AS
 SELECT d.CalendarDate,p.ProductCode,SUM(f.Quantity) Quantity,SUM(f.NetAmount) NetAmount
 FROM dwh.FactSalesOrder f JOIN dwh.DimDate d ON d.DateKey=f.DateKey
 JOIN dwh.DimProduct p ON p.ProductKey=f.ProductKey GROUP BY d.CalendarDate,p.ProductCode;
GO
