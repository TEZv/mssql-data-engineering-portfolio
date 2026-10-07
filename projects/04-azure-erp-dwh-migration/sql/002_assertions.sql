-- Fixture-only: execute in the isolated CI database, never in a deployed warehouse.
DECLARE @initial uniqueidentifier='00000000-0000-0000-0000-000000000001',
 @correction uniqueidentifier='00000000-0000-0000-0000-000000000002',
 @stale uniqueidentifier='00000000-0000-0000-0000-000000000003',
 @conflict uniqueidentifier='00000000-0000-0000-0000-000000000004',
 @bad uniqueidentifier='00000000-0000-0000-0000-000000000005';
INSERT stg.SalesOrder VALUES(@initial,'O1','2026-10-01','C1','P1',10,100,1),(@initial,'O2','2026-10-01','C2','P1',8,80,1);
EXEC etl.usp_LoadSalesOrderBatch @initial,2,180;
EXEC etl.usp_LoadSalesOrderBatch @initial,2,180;
IF (SELECT COUNT(*) FROM dwh.FactSalesOrder)<>2 OR (SELECT COUNT(*) FROM etl.BatchAudit)<>1 THROW 51101,'Replay duplicated data.',1;
INSERT stg.SalesOrder VALUES(@correction,'O1','2026-10-01','C1','P1',12,120,2),(@correction,'O3','2026-10-02','C1','P2',4,40,1);
EXEC etl.usp_LoadSalesOrderBatch @correction,2,160;
IF (SELECT SUM(Quantity) FROM dwh.FactSalesOrder)<>24 OR (SELECT SUM(NetAmount) FROM dwh.FactSalesOrder)<>240 THROW 51102,'Correction must replace, not add.',1;
IF NOT EXISTS (SELECT 1 FROM etl.BatchAudit WHERE BatchId=@correction AND InsertedRows=1 AND UpdatedRows=1) THROW 51103,'Audit is incorrect.',1;
INSERT stg.SalesOrder VALUES(@stale,'O1','2026-10-01','C1','P1',10,100,1);
EXEC etl.usp_LoadSalesOrderBatch @stale,1,100;
IF (SELECT Quantity FROM dwh.FactSalesOrder WHERE SourceOrderId='O1')<>12 THROW 51104,'Stale replay overwrote a correction.',1;
INSERT stg.SalesOrder VALUES(@conflict,'O1','2026-10-01','C1','P1',99,990,2);
BEGIN TRY
 EXEC etl.usp_LoadSalesOrderBatch @conflict,1,990;
 THROW 51105,'Conflict was accepted.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51005 THROW; END CATCH;
INSERT stg.SalesOrder VALUES(@bad,'O4','2026-10-02','C3','P3',1,10,1);
BEGIN TRY
 EXEC etl.usp_LoadSalesOrderBatch @bad,2,10;
 THROW 51106,'Bad source count was accepted.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51003 THROW; END CATCH;
IF EXISTS (SELECT 1 FROM dwh.FactSalesOrder WHERE SourceOrderId='O4') THROW 51107,'Rejected batch mutated target.',1;
UPDATE stg.SalesOrder SET Quantity=0 WHERE BatchId=@bad;
BEGIN TRY
 EXEC etl.usp_LoadSalesOrderBatch @bad,1,10;
 THROW 51108,'Invalid quantity was accepted.',1;
END TRY BEGIN CATCH IF ERROR_NUMBER()<>51004 THROW; END CATCH;
IF (SELECT SUM(NetAmount) FROM dwh.vwDailySales)<>240 THROW 51109,'Star view is incorrect.',1;
PRINT 'Azure ERP DWH assertions passed: replay, correction, stale version, conflict, reconciliation, rejection.';
GO
