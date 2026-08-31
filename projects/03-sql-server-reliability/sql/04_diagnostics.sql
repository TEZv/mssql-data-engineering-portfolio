USE SQLReliabilityPortfolio;
GO

CREATE OR ALTER VIEW diagnostics.vw_IndexUsage
AS
SELECT s.name AS schema_name, o.name AS table_name, i.name AS index_name,
       COALESCE(us.user_seeks, 0) AS user_seeks,
       COALESCE(us.user_scans, 0) AS user_scans,
       COALESCE(us.user_lookups, 0) AS user_lookups,
       COALESCE(us.user_updates, 0) AS user_updates,
       us.last_user_seek, us.last_user_scan, us.last_user_update
FROM sys.indexes i
JOIN sys.objects o ON o.object_id = i.object_id AND o.type = 'U'
JOIN sys.schemas s ON s.schema_id = o.schema_id
LEFT JOIN sys.dm_db_index_usage_stats us
  ON us.database_id = DB_ID() AND us.object_id = i.object_id AND us.index_id = i.index_id
WHERE i.index_id > 0;
GO

CREATE OR ALTER PROCEDURE diagnostics.usp_QueryStoreTopQueries
    @hours_back int = 24,
    @top_n int = 20
AS
BEGIN
    SET NOCOUNT ON;
    IF @hours_back NOT BETWEEN 1 AND 720 OR @top_n NOT BETWEEN 1 AND 100
        THROW 53004, 'Diagnostic range is outside safe limits.', 1;

    SELECT TOP (@top_n)
           q.query_id,
           p.plan_id,
           OBJECT_SCHEMA_NAME(q.object_id) AS object_schema,
           OBJECT_NAME(q.object_id) AS object_name,
           qt.query_sql_text,
           SUM(rs.count_executions) AS executions,
           CAST(SUM(rs.avg_duration * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) / 1000.0 AS decimal(19,2)) AS weighted_avg_duration_ms,
           CAST(SUM(rs.avg_cpu_time * rs.count_executions) / NULLIF(SUM(rs.count_executions), 0) / 1000.0 AS decimal(19,2)) AS weighted_avg_cpu_ms,
           SUM(rs.avg_logical_io_reads * rs.count_executions) AS estimated_logical_reads
    FROM sys.query_store_query_text qt
    JOIN sys.query_store_query q ON q.query_text_id = qt.query_text_id
    JOIN sys.query_store_plan p ON p.query_id = q.query_id
    JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
    JOIN sys.query_store_runtime_stats_interval rsi ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
    WHERE rsi.end_time >= DATEADD(hour, -@hours_back, SYSUTCDATETIME())
    GROUP BY q.query_id, p.plan_id, q.object_id, qt.query_sql_text
    ORDER BY weighted_avg_duration_ms DESC;
END;
GO

CREATE OR ALTER PROCEDURE maintenance.usp_BackupVerificationPlan
    @backup_file nvarchar(4000)
AS
BEGIN
    SET NOCOUNT ON;
    IF @backup_file IS NULL OR @backup_file NOT LIKE '%.bak'
        THROW 53005, 'A .bak file path is required.', 1;

    SELECT N'RESTORE HEADERONLY FROM DISK = N''' + REPLACE(@backup_file, '''', '''''') + N''';' AS header_check,
           N'RESTORE VERIFYONLY FROM DISK = N''' + REPLACE(@backup_file, '''', '''''') + N''' WITH CHECKSUM;' AS verify_check;
END;
GO
