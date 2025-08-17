#Requires -Version 5.1
# Pretty Git Windows smoke test (best-effort)
# Usage: run from repository root after installing gem/binary in PATH
#   powershell -ExecutionPolicy Bypass -File contrib/windows/smoke.ps1

$ErrorActionPreference = 'Stop'

function Assert-ExitCode {
  param(
    [int]$Code,
    [string]$Step
  )
  if ($Code -ne 0) {
    Write-Error "Step failed ($Step) with exit code $Code"
    exit $Code
  }
}

Write-Host "[1/6] pretty-git --version"
pretty-git --version
Assert-ExitCode $LASTEXITCODE 'version'

Write-Host "[2/6] pretty-git --help (first lines)"
pretty-git --help | Select-Object -First 10
Assert-ExitCode $LASTEXITCODE 'help'

Write-Host "[3/6] summary . --format json (first 200 chars)"
$sum = pretty-git summary . --format json 2>$null | Out-String
Assert-ExitCode $LASTEXITCODE 'summary-json'
$sum.Substring(0, [Math]::Min(200, $sum.Length))

Write-Host "[4/6] authors . --since 2025-01-01 --limit 5 --format csv"
pretty-git authors . --since 2025-01-01 --limit 5 --format csv | Select-Object -First 6
Assert-ExitCode $LASTEXITCODE 'authors-csv'

Write-Host "[5/6] files . --path app/**/*.rb --exclude-path spec/** --format md"
pretty-git files . --path 'app/**/*.rb' --exclude-path 'spec/**' --format md | Select-Object -First 10
Assert-ExitCode $LASTEXITCODE 'files-md'

Write-Host "[6/6] languages . --metric loc --format yaml"
pretty-git languages . --metric loc --format yaml | Select-Object -First 12
Assert-ExitCode $LASTEXITCODE 'languages-yaml'

Write-Host "Smoke completed OK"
