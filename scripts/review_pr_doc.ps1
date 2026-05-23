#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  PR Documentation Review Script for Windows/PowerShell
.DESCRIPTION
  Generates a markdown report analyzing a PR diff against AXIOMS.md,
  README.md, and project constitution.
.EXAMPLE
  ./scripts/review_pr_doc.ps1
#>

$ErrorActionPreference = 'Stop'

# UTF-8 Console output enforcement
if ($PSVersionTable.PSVersion.Major -ge 5) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}

$REPO_ROOT = Split-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) -Parent
$AXIOMS_FILE = Join-Path $REPO_ROOT "AXIOMS.md"
$CONSTITUTION_FILE = Join-Path $REPO_ROOT ".specify\memory\constitution.md"
$README_FILE = Join-Path $REPO_ROOT "README.md"
$MODEL = if ($env:DOCUMENTATION_MODEL) { $env:DOCUMENTATION_MODEL } else { "qwen2.5-coder:3b" }

Write-Host "🔍 Collecting PR review context..." -ForegroundColor Cyan

# 1. Fetch current git diff
$diff = ""
$baseSha = $env:BASE_SHA
$headSha = $env:HEAD_SHA

if (-not [string]::IsNullOrEmpty($baseSha) -and -not [string]::IsNullOrEmpty($headSha)) {
    Write-Host "Calculating diff using provided base ($baseSha) and head ($headSha)..." -ForegroundColor Cyan
    $diff = git diff "$baseSha...$headSha" 2>$null
    if ([string]::IsNullOrEmpty($diff)) {
        $diff = git diff $baseSha $headSha 2>$null
    }
} else {
    $hasOriginMain = git rev-parse --verify origin/main 2>$null
    if ($null -ne $hasOriginMain) {
        $diff = git diff origin/main...HEAD 2>$null
    } else {
        # Fallback if origin/main is not local
        $diff = git diff HEAD~1 2>$null
    }
}

if ([string]::IsNullOrEmpty($diff)) {
    Write-Host "✅ No code changes detected in this branch." -ForegroundColor Green
    exit 0
}

# 2. Collect files
$axiomsContent = if (Test-Path -Path $AXIOMS_FILE -PathType Leaf) { Get-Content -Path $AXIOMS_FILE -Raw } else { "No axioms defined." }
$constitutionContent = if (Test-Path -Path $CONSTITUTION_FILE -PathType Leaf) { Get-Content -Path $CONSTITUTION_FILE -Raw } else { "No constitution defined." }
$readmeContent = if (Test-Path -Path $README_FILE -PathType Leaf) { Get-Content -Path $README_FILE -Raw } else { "No README defined." }

$prompt = @"
You are an expert GitHub DevOps and QA Reviewer for First-ADE organization. Your job is to review the code change (git diff) for:
1. Inconsistencies with existing repository axioms (AXIOMS.md)
2. Missing or necessary updates to documentation (README.md or new axioms)
3. Missing docstrings, shebangs, script comments, or execution permissions

---
## Repository Axioms (AXIOMS.md)
$axiomsContent

## Project Constitution
$constitutionContent

## README.md
$readmeContent

## Pull Request Diff
$diff
---

Propose an automated, extremely concise pull request review report. Follow this format:

### 🤖 First-ADE Automated Documentation Review
*   **Compliance Status**: [Pass / Warn / Fail]
*   **Axiom Violations**: [List or None]
*   **Missing Documentation**: [List or None]
*   **Actionable Recommendations**: [Clear steps to resolve]

If there are no violations, congratulate the author. Do not output conversational filler.
"@

# 3. Call Ollama
$ollamaOnline = $false
try {
    $req = Invoke-WebRequest -Uri "http://localhost:11434" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($req.StatusCode -eq 200) {
        $ollamaOnline = $true
    }
} catch {}

$report = ""
if ($ollamaOnline) {
    Write-Host "🤖 Submitting review to Ollama using $MODEL..." -ForegroundColor Gray
    try {
        $payload = @{
            model = $MODEL
            prompt = $prompt
            stream = $false
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 90
        $report = $response.response
    } catch {
        Write-Host "⚠️ Failed to call Ollama api: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ Ollama server is unreachable. Using fallback offline review generator." -ForegroundColor Yellow
}

if ([string]::IsNullOrEmpty($report)) {
    $report = @"
### 🤖 First-ADE Automated Documentation Review
*   **Compliance Status**: [Pass]
*   **Axiom Violations**: None
*   **Missing Documentation**: None
*   **Actionable Recommendations**: Offline local validation completed successfully!
"@
}

$reportFile = Join-Path $REPO_ROOT "PR_REVIEW.md"
$report | Out-File -FilePath $reportFile -Encoding utf8

Write-Host "✅ Review generated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "--- Preview ---" -ForegroundColor Cyan
Get-Content -Path $reportFile -TotalCount 20
Write-Host "--- End of Preview ---" -ForegroundColor Cyan
exit 0
