$ErrorActionPreference = 'Stop'

$version = '1.16.0'
$toolDirectory = Join-Path $PSScriptRoot '..\.tools\terraform'
$terraform = Join-Path $toolDirectory 'terraform.exe'
$archive = Join-Path $env:TEMP "terraform_${version}_windows_amd64.zip"
$downloadUrl = "https://releases.hashicorp.com/terraform/$version/terraform_${version}_windows_amd64.zip"

if (Test-Path -LiteralPath $terraform) {
    & $terraform version
    exit $LASTEXITCODE
}

New-Item -ItemType Directory -Path $toolDirectory -Force | Out-Null
Write-Host "Downloading portable Terraform $version to the repository tool cache..."
& curl.exe -fL --retry 3 --output $archive $downloadUrl
if ($LASTEXITCODE -ne 0) { throw 'Terraform download failed.' }

Expand-Archive -LiteralPath $archive -DestinationPath $toolDirectory -Force
if (-not (Test-Path -LiteralPath $terraform)) { throw 'terraform.exe was not found after extraction.' }

& $terraform version
