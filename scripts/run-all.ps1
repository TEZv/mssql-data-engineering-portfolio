$ErrorActionPreference = 'Stop'
$container = if ($env:SQL_CONTAINER) { $env:SQL_CONTAINER } else { 'mssql-portfolio' }
$password = if ($env:MSSQL_SA_PASSWORD) { $env:MSSQL_SA_PASSWORD } else { 'Portfolio_SQL_2026_Strong!' }

docker compose up -d

$ready = $false
foreach ($attempt in 1..40) {
    docker exec $container /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $password -C -Q 'SELECT 1' 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    Start-Sleep -Seconds 3
}
if (-not $ready) { throw 'SQL Server did not become ready.' }

$projects = @(
    'projects/01-retail-erp-warehouse',
    'projects/02-media-performance-mart',
    'projects/03-sql-server-reliability'
)

foreach ($project in $projects) {
    Get-ChildItem "$project/sql/*.sql" | Sort-Object Name | ForEach-Object {
        Write-Host "Running $($_.FullName)"
        Get-Content -Raw -LiteralPath $_.FullName |
            docker exec -i $container /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $password -C -b -r1 -I
        if ($LASTEXITCODE -ne 0) { throw "Failed: $($_.FullName)" }
    }
}

Write-Host 'All SQL projects and assertions completed.' -ForegroundColor Green
