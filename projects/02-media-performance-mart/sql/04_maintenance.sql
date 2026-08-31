USE MediaPerformancePortfolio;
GO

CREATE OR ALTER PROCEDURE etl.usp_PurgePipelineHistory
    @successful_before datetime2(3),
    @execute bit = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(*) AS candidate_rows
    FROM audit.PipelineRun
    WHERE status = 'SUCCEEDED' AND completed_at < @successful_before;

    IF @execute = 1
    BEGIN
        DELETE FROM audit.PipelineRun
        WHERE status = 'SUCCEEDED' AND completed_at < @successful_before;
    END
END;
GO
