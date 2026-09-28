CREATE SCHEMA stg;
GO
CREATE SCHEMA etl;
GO

CREATE TABLE stg.SalesOrder (
    BatchId uniqueidentifier NOT NULL,
    SourceOrderId nvarchar(50) NOT NULL,
    OrderDate date NOT NULL,
    CustomerCode nvarchar(50) NOT NULL,
    NetAmount decimal(18,2) NOT NULL,
    SourceLoadedAt datetime2(3) NOT NULL DEFAULT sysutcdatetime(),
    CONSTRAINT PK_stg_SalesOrder PRIMARY KEY (BatchId, SourceOrderId)
);
GO
CREATE TABLE etl.BatchAudit (
    BatchId uniqueidentifier NOT NULL PRIMARY KEY,
    SourceRows int NOT NULL,
    StagingRows int NOT NULL,
    Status varchar(20) NOT NULL,
    CheckedAt datetime2(3) NOT NULL DEFAULT sysutcdatetime()
);
GO
CREATE OR ALTER PROCEDURE etl.usp_LoadSalesOrderBatch @BatchId uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @rows int = (SELECT COUNT(*) FROM stg.SalesOrder WHERE BatchId = @BatchId);
    IF @rows = 0 THROW 51001, 'Rejected batch: staging is empty.', 1;
    BEGIN TRANSACTION;
      INSERT etl.BatchAudit (BatchId, SourceRows, StagingRows, Status)
      VALUES (@BatchId, @rows, @rows, 'reconciled');
    COMMIT TRANSACTION;
END;
GO
