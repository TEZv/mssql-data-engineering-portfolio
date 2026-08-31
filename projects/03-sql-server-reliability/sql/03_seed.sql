USE SQLReliabilityPortfolio;
GO

;WITH n AS (
    SELECT TOP (2500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.WorkItem(external_key, status, payload, created_at, closed_at)
SELECT CONCAT('WI-', FORMAT(rn, '000000')),
       CASE WHEN rn % 3 = 0 THEN 'CLOSED' ELSE 'OPEN' END,
       REPLICATE(N'x', 200),
       DATEADD(day, -rn % 730, SYSUTCDATETIME()),
       CASE WHEN rn % 3 = 0 THEN DATEADD(day, -(rn % 730) + 1, SYSUTCDATETIME()) END
FROM n;
GO
