$ErrorActionPreference = 'Stop'

$required = @(
    'README.md',
    'docker-compose.yml',
    'docs/EVIDENCE_MATRIX.md',
    'docs/GITHUB_PORTFOLIO_STRATEGY.md',
    'projects/01-retail-erp-warehouse/sql/05_tests.sql',
    'projects/02-media-performance-mart/sql/05_tests.sql',
    'projects/03-sql-server-reliability/sql/05_tests.sql'
)

foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing required artifact: $path" }
}

$sqlFiles = Get-ChildItem 'projects/*/sql/*.sql'
if ($sqlFiles.Count -lt 15) { throw "Expected at least 15 SQL files, found $($sqlFiles.Count)." }

$allSql = $sqlFiles | Get-Content -Raw
$contracts = @('CREATE OR ALTER PROCEDURE', 'CREATE OR ALTER VIEW', 'CREATE OR ALTER FUNCTION', 'THROW', 'BEGIN TRANSACTION')
foreach ($contract in $contracts) {
    if (-not ($allSql -match [regex]::Escape($contract))) { throw "Missing T-SQL contract: $contract" }
}

Write-Host "Static portfolio check passed: $($sqlFiles.Count) SQL files and all required contracts found." -ForegroundColor Green
