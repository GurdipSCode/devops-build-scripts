Write-Host "🔐 Snyk main branch scans"

.\snyk-scan.ps1 -ScanType "open-source" -SeverityThreshold "medium" -Json -FailOnIssues
.\snyk-scan.ps1 -ScanType "iac" -SeverityThreshold "medium" -Json -FailOnIssues
.\snyk-scan.ps1 -ScanType "code" -SeverityThreshold "high" -Json
