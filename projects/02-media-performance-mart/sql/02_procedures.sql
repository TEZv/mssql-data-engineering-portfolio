USE MediaPerformancePortfolio;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE etl.usp_UpsertDailyMetric
    @pipeline_run_id uniqueidentifier
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @inserted int = 0, @updated int = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        ;WITH latest_source AS (
            SELECT *, ROW_NUMBER() OVER (
                PARTITION BY platform_video_id, metric_date, traffic_source
                ORDER BY source_updated_at DESC
            ) AS source_rank
            FROM stg.DailyVideoMetric
            WHERE pipeline_run_id = @pipeline_run_id
        )
        UPDATE target
           SET views = source.views,
               watch_minutes = source.watch_minutes,
               estimated_revenue = source.estimated_revenue,
               average_view_percentage = source.average_view_percentage,
               source_updated_at = source.source_updated_at,
               loaded_at = SYSUTCDATETIME()
        FROM mart.DailyVideoMetric target
        JOIN ref.Video video ON video.video_key = target.video_key
        JOIN latest_source source
          ON source.platform_video_id = video.platform_video_id
         AND source.metric_date = target.metric_date
         AND source.traffic_source = target.traffic_source
        WHERE source.source_rank = 1
          AND source.source_updated_at > target.source_updated_at;
        SET @updated = @@ROWCOUNT;

        ;WITH latest_source AS (
            SELECT *, ROW_NUMBER() OVER (
                PARTITION BY platform_video_id, metric_date, traffic_source
                ORDER BY source_updated_at DESC
            ) AS source_rank
            FROM stg.DailyVideoMetric
            WHERE pipeline_run_id = @pipeline_run_id
        )
        INSERT mart.DailyVideoMetric(video_key, metric_date, traffic_source, views, watch_minutes,
                                     estimated_revenue, average_view_percentage, source_updated_at)
        SELECT video.video_key, source.metric_date, source.traffic_source, source.views, source.watch_minutes,
               source.estimated_revenue, source.average_view_percentage, source.source_updated_at
        FROM latest_source source
        JOIN ref.Video video ON video.platform_video_id = source.platform_video_id
        WHERE source.source_rank = 1
          AND source.views >= 0 AND source.watch_minutes >= 0 AND source.estimated_revenue >= 0
          AND (source.average_view_percentage IS NULL OR source.average_view_percentage BETWEEN 0 AND 100)
          AND NOT EXISTS (
              SELECT 1 FROM mart.DailyVideoMetric target
              WHERE target.video_key = video.video_key
                AND target.metric_date = source.metric_date
                AND target.traffic_source = source.traffic_source
          );
        SET @inserted = @@ROWCOUNT;

        UPDATE audit.PipelineRun
           SET completed_at = SYSUTCDATETIME(), status = 'SUCCEEDED',
               rows_inserted = @inserted, rows_updated = @updated
         WHERE pipeline_run_id = @pipeline_run_id;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        UPDATE audit.PipelineRun SET completed_at = SYSUTCDATETIME(), status = 'FAILED', error_message = ERROR_MESSAGE()
         WHERE pipeline_run_id = @pipeline_run_id;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER FUNCTION mart.fn_ChannelRetention
(
    @channel_code varchar(30),
    @date_from date,
    @date_to date
)
RETURNS TABLE
AS
RETURN
(
    SELECT c.channel_code,
           SUM(m.views) AS views,
           CAST(SUM(CAST(m.views AS decimal(28,4)) * m.average_view_percentage)
                / NULLIF(SUM(CASE WHEN m.average_view_percentage IS NOT NULL THEN CAST(m.views AS decimal(28,4)) END), 0)
                AS decimal(9,4)) AS weighted_retention_pct
    FROM mart.DailyVideoMetric m
    JOIN ref.Video v ON v.video_key = m.video_key
    JOIN ref.Channel c ON c.channel_key = v.channel_key
    WHERE c.channel_code = @channel_code
      AND m.metric_date >= @date_from AND m.metric_date <= @date_to
    GROUP BY c.channel_code
);
GO

CREATE OR ALTER VIEW mart.vw_VideoPerformance
AS
SELECT v.platform_video_id, v.title, c.channel_code, m.metric_date,
       SUM(m.views) AS views,
       SUM(m.watch_minutes) AS watch_minutes,
       SUM(m.estimated_revenue) AS estimated_revenue,
       CAST(SUM(CAST(m.views AS decimal(28,4)) * m.average_view_percentage)
            / NULLIF(SUM(CASE WHEN m.average_view_percentage IS NOT NULL THEN CAST(m.views AS decimal(28,4)) END), 0)
            AS decimal(9,4)) AS weighted_retention_pct,
       SUM(SUM(m.views)) OVER (
           PARTITION BY v.video_key ORDER BY m.metric_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ) AS rolling_7d_views
FROM mart.DailyVideoMetric m
JOIN ref.Video v ON v.video_key = m.video_key
JOIN ref.Channel c ON c.channel_key = v.channel_key
GROUP BY v.video_key, v.platform_video_id, v.title, c.channel_code, m.metric_date;
GO
