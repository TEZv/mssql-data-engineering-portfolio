USE MediaPerformancePortfolio;
GO

IF (SELECT COUNT(*) FROM mart.DailyVideoMetric) <> 3
    THROW 52001, 'Unexpected daily metric grain or duplicate facts.', 1;

IF NOT EXISTS (
    SELECT 1 FROM mart.DailyVideoMetric m
    JOIN ref.Video v ON v.video_key = m.video_key
    WHERE v.platform_video_id = 'vid-001' AND metric_date = '2026-08-02' AND views = 120
)
    THROW 52002, 'Late-arriving correction was not applied.', 1;

DECLARE @weighted decimal(9,4) = (
    SELECT weighted_retention_pct FROM mart.fn_ChannelRetention('NEWS-UA', '2026-08-02', '2026-08-02')
);
IF @weighted <> 44.7059
    THROW 52003, 'Weighted retention calculation is incorrect.', 1;

IF EXISTS (
    SELECT video_key, metric_date, traffic_source
    FROM mart.DailyVideoMetric
    GROUP BY video_key, metric_date, traffic_source
    HAVING COUNT(*) > 1
)
    THROW 52004, 'Fact grain is not unique.', 1;

IF (SELECT rows_updated FROM audit.PipelineRun WHERE pipeline_run_id = '22222222-2222-2222-2222-222222222223') <> 1
    THROW 52005, 'Correction audit count is incorrect.', 1;

PRINT 'Media performance assertions passed.';
GO
