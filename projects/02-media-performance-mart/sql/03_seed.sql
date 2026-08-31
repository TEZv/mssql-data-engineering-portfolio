USE MediaPerformancePortfolio;
GO

INSERT ref.Channel(channel_code, channel_name) VALUES ('NEWS-UA', N'Synthetic News UA');
DECLARE @channel_key int = SCOPE_IDENTITY();
INSERT ref.Video(channel_key, platform_video_id, title, published_at) VALUES
(@channel_key, 'vid-001', N'Morning update', '2026-08-01T08:00:00'),
(@channel_key, 'vid-002', N'Evening analysis', '2026-08-01T18:00:00');

DECLARE @run uniqueidentifier = '22222222-2222-2222-2222-222222222222';
INSERT audit.PipelineRun(pipeline_run_id, pipeline_name, status) VALUES (@run, 'daily_video_metrics', 'RUNNING');
INSERT stg.DailyVideoMetric(pipeline_run_id, platform_video_id, metric_date, traffic_source, views,
                            watch_minutes, estimated_revenue, average_view_percentage, source_updated_at) VALUES
(@run, 'vid-001', '2026-08-02', 'ORGANIC', 100, 800.0000, 12.0000, 80.0000, '2026-08-03'),
(@run, 'vid-002', '2026-08-02', 'ORGANIC', 900, 3600.0000, 45.0000, 40.0000, '2026-08-03'),
(@run, 'vid-001', '2026-08-03', 'ORGANIC', 50, 350.0000, 5.0000, 70.0000, '2026-08-04');
EXEC etl.usp_UpsertDailyMetric @run;

DECLARE @correction uniqueidentifier = '22222222-2222-2222-2222-222222222223';
INSERT audit.PipelineRun(pipeline_run_id, pipeline_name, status) VALUES (@correction, 'daily_video_metrics', 'RUNNING');
INSERT stg.DailyVideoMetric(pipeline_run_id, platform_video_id, metric_date, traffic_source, views,
                            watch_minutes, estimated_revenue, average_view_percentage, source_updated_at) VALUES
(@correction, 'vid-001', '2026-08-02', 'ORGANIC', 120, 960.0000, 14.0000, 80.0000, '2026-08-05');
EXEC etl.usp_UpsertDailyMetric @correction;
GO
