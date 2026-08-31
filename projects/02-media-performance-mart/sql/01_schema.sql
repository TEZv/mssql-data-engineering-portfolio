USE MediaPerformancePortfolio;
GO

DROP VIEW IF EXISTS mart.vw_VideoPerformance;
DROP FUNCTION IF EXISTS mart.fn_ChannelRetention;
DROP TABLE IF EXISTS mart.DailyVideoMetric;
DROP TABLE IF EXISTS stg.DailyVideoMetric;
DROP TABLE IF EXISTS ref.Video;
DROP TABLE IF EXISTS ref.Channel;
DROP TABLE IF EXISTS audit.PipelineRun;
GO

CREATE TABLE audit.PipelineRun (
    pipeline_run_id uniqueidentifier CONSTRAINT PK_PipelineRun PRIMARY KEY,
    pipeline_name sysname NOT NULL,
    started_at datetime2(3) NOT NULL CONSTRAINT DF_PipelineRun_started DEFAULT SYSUTCDATETIME(),
    completed_at datetime2(3) NULL,
    status varchar(12) NOT NULL CONSTRAINT CK_PipelineRun_status CHECK (status IN ('RUNNING','SUCCEEDED','FAILED')),
    rows_inserted int NOT NULL CONSTRAINT DF_PipelineRun_ins DEFAULT 0,
    rows_updated int NOT NULL CONSTRAINT DF_PipelineRun_upd DEFAULT 0,
    error_message nvarchar(2048) NULL
);

CREATE TABLE ref.Channel (
    channel_key int IDENTITY(1,1) CONSTRAINT PK_Channel PRIMARY KEY,
    channel_code varchar(30) NOT NULL CONSTRAINT UQ_Channel_code UNIQUE,
    channel_name nvarchar(200) NOT NULL
);

CREATE TABLE ref.Video (
    video_key int IDENTITY(1,1) CONSTRAINT PK_Video PRIMARY KEY,
    channel_key int NOT NULL CONSTRAINT FK_Video_Channel REFERENCES ref.Channel(channel_key),
    platform_video_id varchar(50) NOT NULL CONSTRAINT UQ_Video_platform UNIQUE,
    title nvarchar(300) NOT NULL,
    published_at datetime2(0) NOT NULL
);

CREATE TABLE stg.DailyVideoMetric (
    pipeline_run_id uniqueidentifier NOT NULL,
    platform_video_id varchar(50) NOT NULL,
    metric_date date NOT NULL,
    traffic_source varchar(30) NOT NULL,
    views bigint NOT NULL,
    watch_minutes decimal(19,4) NOT NULL,
    estimated_revenue decimal(19,4) NOT NULL,
    average_view_percentage decimal(9,4) NULL,
    source_updated_at datetime2(3) NOT NULL
);

CREATE TABLE mart.DailyVideoMetric (
    daily_metric_key bigint IDENTITY(1,1) CONSTRAINT PK_DailyVideoMetric PRIMARY KEY,
    video_key int NOT NULL CONSTRAINT FK_DailyMetric_Video REFERENCES ref.Video(video_key),
    metric_date date NOT NULL,
    traffic_source varchar(30) NOT NULL,
    views bigint NOT NULL CONSTRAINT CK_DailyMetric_views CHECK (views >= 0),
    watch_minutes decimal(19,4) NOT NULL CONSTRAINT CK_DailyMetric_watch CHECK (watch_minutes >= 0),
    estimated_revenue decimal(19,4) NOT NULL CONSTRAINT CK_DailyMetric_revenue CHECK (estimated_revenue >= 0),
    average_view_percentage decimal(9,4) NULL CONSTRAINT CK_DailyMetric_retention CHECK (average_view_percentage BETWEEN 0 AND 100),
    source_updated_at datetime2(3) NOT NULL,
    loaded_at datetime2(3) NOT NULL CONSTRAINT DF_DailyMetric_loaded DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_DailyMetric_grain UNIQUE (video_key, metric_date, traffic_source)
);
CREATE INDEX IX_DailyMetric_reporting ON mart.DailyVideoMetric(metric_date, video_key)
    INCLUDE (views, watch_minutes, estimated_revenue, average_view_percentage, traffic_source);
GO
