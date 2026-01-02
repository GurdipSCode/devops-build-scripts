
param (
    [string]$Config = "cliff.toml",
    [string]$Output = "CHANGELOG.md",
    [string]$Tag,
    [switch]$FailOnDirty
)

Write-Host "📝 Running git-cliff"

# Ensure git-cliff is installed
if (-not (Get-Command git-cliff -ErrorAction SilentlyContinue)) {
    Write-Host "Installing git-cliff..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id orhun.git-cliff -e --silent
    } else {
        throw "git-cliff not found and winget is unavailable"
    }
}

# Optional dirty check
if ($FailOnDirty) {
    $status = git status --porcelain
    if ($status) {
        Write-Error "❌ Working tree is dirty"
        exit 1
    }
}

$cliffArgs = @()

if (Test-Path $Config) {
    $cliffArgs += "--config `"$Config`""
}

if ($Tag) {
    $cliffArgs += "--tag `"$Tag`""
}

$cliffArgs += "--output `"$Output`""

Write-Host "Running:"
Write-Host "git-cliff $($cliffArgs -join ' ')"

git-cliff @cliffArgs

if ($LASTEXITCODE -ne 0) {
    throw "❌ git-cliff failed"
}

Write-Host "✅ Changelog generated at $Output"
