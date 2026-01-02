param (
    [string]$Config = "p/default",
    [string]$BaselineRef = "origin/main"
)

Write-Host "🔍 Running Semgrep PR scan"

# Ensure Semgrep is installed
if (-not (Get-Command semgrep -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Semgrep..."
    pip install --user semgrep
    $env:PATH += ";$env:APPDATA\Python\Python*\Scripts"
}

# Fetch baseline for diff-aware scan
git fetch origin main

$semgrepArgs = @(
    "scan",
    "--config=$Config",
    "--baseline-ref=$BaselineRef",
    "--error",
    "--metrics=off",
    "--quiet"
)

Write-Host "Running:"
Write-Host "semgrep $($semgrepArgs -join ' ')"

semgrep @semgrepArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Semgrep failed PR checks"
    exit 1
}

Write-Host "✅ Semgrep PR scan passed"
