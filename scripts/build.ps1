#------------------------------------------------------------------------------
# .NET Core Build Script
# Usage: .\dotnet-build.ps1 [-ProjectPath <path>] [-Configuration <config>] [-Runtime <rid>]
#------------------------------------------------------------------------------

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = ".",

    [Parameter()]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [Parameter()]
    [string]$Runtime,

    [Parameter()]
    [string]$OutputDir = ".\publish",

    [Parameter()]
    [switch]$Restore,

    [Parameter()]
    [switch]$Clean,

    [Parameter()]
    [switch]$Test,

    [Parameter()]
    [switch]$Publish,

    [Parameter()]
    [switch]$SelfContained,

    [Parameter()]
    [switch]$SingleFile,

    [Parameter()]
    [string]$Framework
)

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

$ErrorActionPreference = "Stop"
$StartTime = Get-Date

function Write-Step {
    param([string]$Message)
    Write-Host "`n===> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

#------------------------------------------------------------------------------
# Verify .NET SDK
#------------------------------------------------------------------------------

Write-Step "Checking .NET SDK"

try {
    $dotnetVersion = dotnet --version
    Write-Success "Found .NET SDK version: $dotnetVersion"
}
catch {
    Write-Error ".NET SDK not found. Please install from https://dotnet.microsoft.com/download"
    exit 1
}

#------------------------------------------------------------------------------
# Resolve Project Path
#------------------------------------------------------------------------------

$ProjectPath = Resolve-Path $ProjectPath -ErrorAction SilentlyContinue

if (-not $ProjectPath) {
    Write-Error "Project path not found"
    exit 1
}

Write-Host "Project Path: $ProjectPath"

# Find solution or project file
$SolutionFile = Get-ChildItem -Path $ProjectPath -Filter "*.sln" -ErrorAction SilentlyContinue | Select-Object -First 1
$ProjectFile = Get-ChildItem -Path $ProjectPath -Filter "*.csproj" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($SolutionFile) {
    $BuildTarget = $SolutionFile.FullName
    Write-Host "Found solution: $($SolutionFile.Name)"
}
elseif ($ProjectFile) {
    $BuildTarget = $ProjectFile.FullName
    Write-Host "Found project: $($ProjectFile.Name)"
}
else {
    Write-Error "No .sln or .csproj file found in $ProjectPath"
    exit 1
}

#------------------------------------------------------------------------------
# Clean (optional)
#------------------------------------------------------------------------------

if ($Clean) {
    Write-Step "Cleaning solution"
    
    dotnet clean $BuildTarget --configuration $Configuration
    
    # Remove bin/obj directories
    Get-ChildItem -Path $ProjectPath -Include bin, obj -Recurse -Directory | ForEach-Object {
        Write-Host "Removing: $($_.FullName)"
        Remove-Item $_.FullName -Recurse -Force
    }
    
    Write-Success "Clean completed"
}

#------------------------------------------------------------------------------
# Restore
#------------------------------------------------------------------------------

if ($Restore -or -not $Clean) {
    Write-Step "Restoring NuGet packages"
    
    dotnet restore $BuildTarget
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Restore failed"
        exit $LASTEXITCODE
    }
    
    Write-Success "Restore completed"
}

#------------------------------------------------------------------------------
# Build
#------------------------------------------------------------------------------

Write-Step "Building project ($Configuration)"

$buildArgs = @(
    "build"
    $BuildTarget
    "--configuration", $Configuration
    "--no-restore"
)

if ($Framework) {
    $buildArgs += "--framework", $Framework
}

if ($Runtime) {
    $buildArgs += "--runtime", $Runtime
}

Write-Host "Running: dotnet $($buildArgs -join ' ')"
& dotnet @buildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit $LASTEXITCODE
}

Write-Success "Build completed"

#------------------------------------------------------------------------------
# Test (optional)
#------------------------------------------------------------------------------

if ($Test) {
    Write-Step "Running tests"
    
    $testArgs = @(
        "test"
        $BuildTarget
        "--configuration", $Configuration
        "--no-build"
        "--logger", "trx"
        "--results-directory", ".\TestResults"
    )
    
    & dotnet @testArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Tests failed"
        exit $LASTEXITCODE
    }
    
    Write-Success "Tests passed"
}

#------------------------------------------------------------------------------
# Publish (optional)
#------------------------------------------------------------------------------

if ($Publish) {
    Write-Step "Publishing application"
    
    $publishArgs = @(
        "publish"
        $BuildTarget
        "--configuration", $Configuration
        "--output", $OutputDir
        "--no-build"
    )
    
    if ($Runtime) {
        $publishArgs += "--runtime", $Runtime
    }
    
    if ($SelfContained) {
        $publishArgs += "--self-contained", "true"
    }
    else {
        $publishArgs += "--self-contained", "false"
    }
    
    if ($SingleFile) {
        $publishArgs += "-p:PublishSingleFile=true"
    }
    
    if ($Framework) {
        $publishArgs += "--framework", $Framework
    }
    
    Write-Host "Running: dotnet $($publishArgs -join ' ')"
    & dotnet @publishArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Publish failed"
        exit $LASTEXITCODE
    }
    
    Write-Success "Published to: $OutputDir"
}

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------

$EndTime = Get-Date
$Duration = $EndTime - $StartTime

Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
Write-Success "BUILD SUCCESSFUL"
Write-Host "Duration: $($Duration.ToString('mm\:ss'))"
Write-Host "=" * 60 -ForegroundColor Cyan
