USE SQLReliabilityPortfolio;
GO

DROP VIEW IF EXISTS diagnostics.vw_IndexUsage;
DROP TABLE IF EXISTS dbo.WorkItem;
DROP TABLE IF EXISTS maintenance.OperationLog;
GO

CREATE TABLE maintenance.OperationLog (
    operation_log_id bigint IDENTITY(1,1) CONSTRAINT PK_OperationLog PRIMARY KEY,
    operation_name sysname NOT NULL,
    target_name nvarchar(776) NULL,
    command_text nvarchar(max) NULL,
    mode varchar(10) NOT NULL CONSTRAINT CK_OperationLog_mode CHECK (mode IN ('DRY_RUN','EXECUTE')),
    status varchar(12) NOT NULL CONSTRAINT CK_OperationLog_status CHECK (status IN ('PLANNED','SUCCEEDED','FAILED','SKIPPED')),
    started_at datetime2(3) NOT NULL CONSTRAINT DF_OperationLog_started DEFAULT SYSUTCDATETIME(),
    completed_at datetime2(3) NULL,
    duration_ms int NULL,
    error_number int NULL,
    error_message nvarchar(2048) NULL
);
CREATE INDEX IX_OperationLog_recent ON maintenance.OperationLog(started_at DESC) INCLUDE (operation_name, status, target_name);

CREATE TABLE dbo.WorkItem (
    work_item_id bigint IDENTITY(1,1) CONSTRAINT PK_WorkItem PRIMARY KEY,
    external_key varchar(40) NOT NULL CONSTRAINT UQ_WorkItem_external UNIQUE,
    status varchar(20) NOT NULL,
    payload nvarchar(1000) NOT NULL,
    created_at datetime2(3) NOT NULL,
    closed_at datetime2(3) NULL,
    CONSTRAINT CK_WorkItem_dates CHECK (closed_at IS NULL OR closed_at >= created_at)
);
CREATE INDEX IX_WorkItem_status_created ON dbo.WorkItem(status, created_at) INCLUDE (closed_at);
GO
