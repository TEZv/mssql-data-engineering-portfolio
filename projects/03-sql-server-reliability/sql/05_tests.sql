USE SQLReliabilityPortfolio;
GO

IF (SELECT COUNT(*) FROM dbo.WorkItem) <> 2500
    THROW 53010, 'Synthetic workload fixture count is incorrect.', 1;

EXEC maintenance.usp_IntegrityCheck @execute = 0;
IF NOT EXISTS (
    SELECT 1 FROM maintenance.OperationLog
    WHERE operation_name = 'DBCC_CHECKDB' AND mode = 'DRY_RUN' AND command_text LIKE 'DBCC CHECKDB%'
)
    THROW 53011, 'Integrity check did not create a dry-run audit record.', 1;

DECLARE @before int = (SELECT COUNT(*) FROM dbo.WorkItem);
EXEC maintenance.usp_PurgeClosedWorkItems @closed_before = '2026-01-01', @batch_size = 100, @execute = 0;
IF (SELECT COUNT(*) FROM dbo.WorkItem) <> @before
    THROW 53012, 'Dry-run retention procedure modified data.', 1;

BEGIN TRY
    EXEC maintenance.usp_IndexCare @reorganize_from = 30, @rebuild_from = 10, @execute = 0;
    THROW 53013, 'Invalid thresholds should have been rejected.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 53001 THROW;
END CATCH;

IF NOT EXISTS (SELECT 1 FROM diagnostics.vw_IndexUsage WHERE table_name = 'WorkItem')
    THROW 53014, 'Index usage diagnostic view is incomplete.', 1;

EXEC maintenance.usp_BackupVerificationPlan @backup_file = N'/var/opt/mssql/backup/SQLReliabilityPortfolio.bak';

PRINT 'SQL Server reliability assertions passed.';
GO
