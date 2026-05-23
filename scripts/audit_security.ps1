#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  Automated Security & Compliance Auditor for Windows/PowerShell
.DESCRIPTION
  Audits GitHub Actions SHA-pinning, checks shell script hygiene,
  and feeds findings into local Ollama or offline fallback template.
.EXAMPLE
  ./scripts/audit_security.ps1
#>

$ErrorActionPreference = 'Continue'

# UTF-8 Console output enforcement
if ($PSVersionTable.PSVersion.Major -ge 5) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}

$REPO_ROOT = Split-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) -Parent
$MODEL = if ($env:AUDIT_MODEL) { $env:AUDIT_MODEL } else { "qwen2.5-coder:3b" }

Write-Host "🔍 Running Automated Security & Compliance Auditor..." -ForegroundColor Cyan

# 1. Check third-party Actions for commit SHA-pinning
Write-Host "Checking GitHub Actions for commit SHA-pinning compliance..." -ForegroundColor Cyan
$unpinnedActions = @()

$wfDir = Join-Path $REPO_ROOT ".github\workflows"
if (Test-Path -Path $wfDir -PathType Container) {
    $workflows = Get-ChildItem -Path $wfDir -Include "*.yml", "*.yaml" -File -Recurse
    foreach ($wf in $workflows) {
        $wfName = $wf.Name
        $lines = Get-Content -Path $wf.FullName
        foreach ($line in $lines) {
            if ($line -match 'uses:\s*([^\s"'']+)') {
                $actionRef = $Matches[1].Trim()
                # Skip local actions (starting with ./ or .)
                if ($actionRef.StartsWith("./") -or $actionRef.StartsWith(".") -or [string]::IsNullOrEmpty($actionRef)) {
                    continue
                }
                # Check if pinned to a 40-character SHA (e.g. actions/checkout@v4 vs actions/checkout@b4ffde... )
                if ($actionRef -match '@[0-9a-fA-F]{40}$') {
                    # secured
                } else {
                    $unpinnedActions += "  * In $wfName: '$actionRef'"
                }
            }
        }
    }
}

# 2. Check shell and PowerShell scripts for vulnerable patterns
Write-Host "Auditing scripts for secure execution patterns..." -ForegroundColor Cyan
$scriptVulns = @()

$scriptsDir = Join-Path $REPO_ROOT "scripts"
$scripts = Get-ChildItem -Path $scriptsDir -Include "*.sh", "*.ps1" -File
foreach ($script in $scripts) {
    if ($script.Name -eq "audit_security.sh" -or $script.Name -eq "audit_security.ps1") {
        continue
    }
    
    $content = Get-Content -Path $script.FullName -Raw
    
    # Check for eval in shell scripts
    if ($script.Extension -eq ".sh" -and $content -match '\beval\b') {
        $scriptVulns += "  * $($script.Name) contains 'eval' command"
    }
    # Check for Invoke-Expression (iex) in PowerShell scripts
    if ($script.Extension -eq ".ps1" -and ($content -match '\bInvoke-Expression\b' -or $content -match '\biex\b')) {
        $scriptVulns += "  * $($script.Name) contains 'Invoke-Expression' or 'iex' command"
    }
    # Check for raw downloads executed directly (e.g. curl | sh, or Invoke-WebRequest | iex)
    if ($script.Extension -eq ".sh" -and $content -match 'curl\s+.*\|\s*(ba)?sh') {
        $scriptVulns += "  * $($script.Name) contains direct piped execution of curl downloads"
    }
    if ($script.Extension -eq ".ps1" -and $content -match 'iwr\s+.*\|\s*iex|Invoke-WebRequest\s+.*\|\s*iex') {
        $scriptVulns += "  * $($script.Name) contains direct piped execution of web downloads"
    }
}

# Assemble findings context
$findingsContext = ""
if ($unpinnedActions.Count -gt 0) {
    $findingsContext += "`n### Unpinned GitHub Actions Found:`n" + ($unpinnedActions -join "`n")
} else {
    $findingsContext += "`n### Unpinned GitHub Actions Found:`n  * None. All third-party actions are securely pinned to commit SHAs!"
}

if ($scriptVulns.Count -gt 0) {
    $findingsContext += "`n`n### Script Hygiene Violations:`n" + ($scriptVulns -join "`n")
} else {
    $findingsContext += "`n`n### Script Hygiene Violations:`n  * None. Scripts follow secure practices!"
}

# 3. Call local Ollama model to formulate the report or fallback offline
$prompt = @"
You are an expert GitHub DevOps Security Auditor. Analyze the security audit findings below and formulate an automated markdown report.

---
## Security Findings
$findingsContext
---

Compile a highly professional report. It MUST strictly follow this exact format:

### 🚨 Automated Security & Compliance Auditor Report
*   **Compliance Status**: [Pass / Warn / Fail] (Fail if there are critical issues, Warn if there are unpinned actions or minor script warnings, Pass if clean)
*   **Vulnerabilities Found**: [Summarize findings or None]
*   **Actionable Recommendations**: [Provide concrete steps to pin actions to their commit SHAs and fix any script warnings]

Ensure all recommendations are actionable and direct. Do not write conversational preambles or postambles.
"@

$ollamaOnline = $false
try {
    $req = Invoke-WebRequest -Uri "http://localhost:11434" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($req.StatusCode -eq 200) {
        $ollamaOnline = $true
    }
} catch {}

$report = ""
if ($ollamaOnline) {
    Write-Host "🤖 Submitting findings to local Ollama ($MODEL)..." -ForegroundColor Gray
    try {
        $payload = @{
            model = $MODEL
            prompt = $prompt
            stream = $false
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 30
        $report = $response.response
    } catch {
        Write-Host "⚠️ Failed to call Ollama api: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Ollama server is unreachable. Using fallback offline security report generator." -ForegroundColor Yellow
}

$reportFile = Join-Path $REPO_ROOT "SECURITY_AUDIT.md"

if ([string]::IsNullOrEmpty($report)) {
    Write-Host "❌ Failed to generate security report from local Ollama. Falling back..." -ForegroundColor Yellow
    $sb = New-Object System.Text.StringBuilder
    $sb.AppendLine("### 🚨 Automated Security & Compliance Auditor Report") | Out-Null
    if ($unpinnedActions.Count -gt 0 -or $scriptVulns.Count -gt 0) {
        $sb.AppendLine("*   **Compliance Status**: [Warn]") | Out-Null
        $sb.AppendLine("*   **Vulnerabilities Found**:") | Out-Null
        if ($unpinnedActions.Count -gt 0) {
            $sb.AppendLine("    - Unpinned third-party actions were identified.") | Out-Null
        }
        if ($scriptVulns.Count -gt 0) {
            $sb.AppendLine("    - Dangerous script commands or patterns were detected.") | Out-Null
        }
        $sb.AppendLine("*   **Actionable Recommendations**:") | Out-Null
        $sb.AppendLine("    1. Pin third-party GitHub Actions to explicit commit SHAs.") | Out-Null
        $sb.AppendLine("    2. Review scripts to avoid direct execution of downloads or raw evaluations.") | Out-Null
    } else {
        $sb.AppendLine("*   **Compliance Status**: [Pass]") | Out-Null
        $sb.AppendLine("*   **Vulnerabilities Found**: None") | Out-Null
        $sb.AppendLine("*   **Actionable Recommendations**: All clean! Workflows are fully pinned and secure.") | Out-Null
    }
    $report = $sb.ToString()
} else {
    Write-Host "✅ Security report compiled successfully!" -ForegroundColor Green
}

$report | Out-File -FilePath $reportFile -Encoding utf8

Write-Host "--- Security Audit Preview ---" -ForegroundColor Cyan
Get-Content -Path $reportFile -TotalCount 20
Write-Host "--- End of Preview ---" -ForegroundColor Cyan

# Set exit code based on report status
$contentCheck = Get-Content -Path $reportFile -Raw
if ($contentCheck -match "Compliance Status: \[Fail\]") {
    Write-Host "❌ Security Audit Failed!" -ForegroundColor Red
    exit 1
} elseif ($contentCheck -match "Compliance Status: \[Warn\]") {
    Write-Host "⚠️ Security Audit completed with warnings." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "✅ Security Audit passed cleanly!" -ForegroundColor Green
    exit 0
}
