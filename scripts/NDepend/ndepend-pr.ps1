param (
    [string]$NDependConsoleExe = "C:\Program Files\NDepend\NDepend.Console.exe",
    [string]$ProjectFile = "MySolution.ndproj"
)

Write-Host "🔍 NDepend PR analysis"

# Baseline should be generated from main branch
.\ndepend-analysis.ps1 `
  -NDependConsoleExe $NDependConsoleExe `
  -ProjectFile $ProjectFile `
  -BaselineDir "ndepend-baseline"
