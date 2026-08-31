USE SQLReliabilityPortfolio;
GO

CREATE OR ALTER PROCEDURE maintenance.usp_IntegrityCheck
    @execute bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @command nvarchar(max) = N'DBCC CHECKDB (' + QUOTENAME(DB_NAME(), '''') + N') WITH NO_INFOMSGS, ALL_ERRORMSGS;';
    DECLARE @log_id bigint;

    INSERT maintenance.OperationLog(operation_name, target_name, command_text, mode, status)
    VALUES ('DBCC_CHECKDB', DB_NAME(), @command, IIF(@execute = 1, 'EXECUTE', 'DRY_RUN'), IIF(@execute = 1, 'PLANNED', 'PLANNED'));
    SET @log_id = SCOPE_IDENTITY();

    IF @execute = 0 RETURN;

    BEGIN TRY
        EXEC sys.sp_executesql @command;
        UPDATE maintenance.OperationLog SET status = 'SUCCEEDED', completed_at = SYSUTCDATETIME() WHERE operation_log_id = @log_id;
    END TRY
    BEGIN CATCH
        UPDATE maintenance.OperationLog
           SET status = 'FAILED', completed_at = SYSUTCDATETIME(), error_number = ERROR_NUMBER(), error_message = ERROR_MESSAGE()
         WHERE operation_log_id = @log_id;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE maintenance.usp_IndexCare
    @reorganize_from decimal(5,2) = 10.0,
    @rebuild_from decimal(5,2) = 30.0,
    @min_page_count int = 1000,
    @execute bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @reorganize_from < 0 OR @rebuild_from <= @reorganize_from OR @min_page_count < 0
        THROW 53001, 'Invalid index maintenance thresholds.', 1;

    DECLARE @lock_result int;
    EXEC @lock_result = sys.sp_getapplock
        @Resource = N'SQLReliabilityPortfolio.IndexCare', @LockMode = 'Exclusive', @LockOwner = 'Session', @LockTimeout = 0;
    IF @lock_result < 0 THROW 53002, 'Another index maintenance session is already running.', 1;

    BEGIN TRY
        DECLARE @candidates TABLE (
            target_name nvarchar(776) NOT NULL,
            command_text nvarchar(max) NOT NULL,
            fragmentation decimal(9,4) NOT NULL,
            page_count bigint NOT NULL
        );

        INSERT @candidates(target_name, command_text, fragmentation, page_count)
        SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) + N'.' + QUOTENAME(i.name),
               N'ALTER INDEX ' + QUOTENAME(i.name) + N' ON ' + QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) +
               CASE WHEN ips.avg_fragmentation_in_percent >= @rebuild_from THEN N' REBUILD;' ELSE N' REORGANIZE;' END,
               ips.avg_fragmentation_in_percent, ips.page_count
        FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
        JOIN sys.indexes i ON i.object_id = ips.object_id AND i.index_id = ips.index_id
        JOIN sys.objects o ON o.object_id = i.object_id AND o.type = 'U'
        JOIN sys.schemas s ON s.schema_id = o.schema_id
        WHERE i.index_id > 0 AND i.is_disabled = 0
          AND ips.page_count >= @min_page_count
          AND ips.avg_fragmentation_in_percent >= @reorganize_from;

        DECLARE @target nvarchar(776), @command nvarchar(max), @log_id bigint;
        DECLARE index_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT target_name, command_text FROM @candidates;
        OPEN index_cursor;
        FETCH NEXT FROM index_cursor INTO @target, @command;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT maintenance.OperationLog(operation_name, target_name, command_text, mode, status)
            VALUES ('INDEX_CARE', @target, @command, IIF(@execute = 1, 'EXECUTE', 'DRY_RUN'), 'PLANNED');
            SET @log_id = SCOPE_IDENTITY();

            IF @execute = 1
            BEGIN TRY
                EXEC sys.sp_executesql @command;
                UPDATE maintenance.OperationLog SET status = 'SUCCEEDED', completed_at = SYSUTCDATETIME() WHERE operation_log_id = @log_id;
            END TRY
            BEGIN CATCH
                UPDATE maintenance.OperationLog
                   SET status = 'FAILED', completed_at = SYSUTCDATETIME(), error_number = ERROR_NUMBER(), error_message = ERROR_MESSAGE()
                 WHERE operation_log_id = @log_id;
            END CATCH;
            FETCH NEXT FROM index_cursor INTO @target, @command;
        END
        CLOSE index_cursor;
        DEALLOCATE index_cursor;
        EXEC sys.sp_releaseapplock @Resource = N'SQLReliabilityPortfolio.IndexCare', @LockOwner = 'Session';

        SELECT * FROM @candidates ORDER BY fragmentation DESC;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'index_cursor') >= -1
        BEGIN
            IF CURSOR_STATUS('local', 'index_cursor') > -1 CLOSE index_cursor;
            DEALLOCATE index_cursor;
        END;
        EXEC sys.sp_releaseapplock @Resource = N'SQLReliabilityPortfolio.IndexCare', @LockOwner = 'Session';
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE maintenance.usp_PurgeClosedWorkItems
    @closed_before datetime2(3),
    @batch_size int = 1000,
    @execute bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @batch_size NOT BETWEEN 1 AND 10000 THROW 53003, 'Batch size must be between 1 and 10000.', 1;

    IF @execute = 0
    BEGIN
        SELECT COUNT(*) AS candidate_rows FROM dbo.WorkItem WHERE status = 'CLOSED' AND closed_at < @closed_before;
        RETURN;
    END;

    DECLARE @deleted int = 1;
    WHILE @deleted > 0
    BEGIN
        BEGIN TRANSACTION;
        DELETE TOP (@batch_size) FROM dbo.WorkItem WHERE status = 'CLOSED' AND closed_at < @closed_before;
        SET @deleted = @@ROWCOUNT;
        COMMIT;
    END;
END;
GO
