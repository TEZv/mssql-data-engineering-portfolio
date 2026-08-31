$ErrorActionPreference = 'Stop'

$terraform = Join-Path $PSScriptRoot '..\.tools\terraform\terraform.exe'
$iacDirectory = Join-Path $PSScriptRoot '..\infra\azure-sql'

if (-not (Test-Path -LiteralPath $terraform)) {
    throw 'Portable Terraform is missing. Run scripts/get-terraform.ps1 first.'
}

& $terraform "-chdir=$iacDirectory" fmt -check -recursive
if ($LASTEXITCODE -ne 0) { throw 'terraform fmt check failed.' }

& $terraform "-chdir=$iacDirectory" init -backend=false -input=false
if ($LASTEXITCODE -ne 0) { throw 'terraform init failed.' }

& $terraform "-chdir=$iacDirectory" validate
if ($LASTEXITCODE -ne 0) { throw 'terraform validate failed.' }

Write-Host 'Terraform format, initialization and validation passed.' -ForegroundColor Green
