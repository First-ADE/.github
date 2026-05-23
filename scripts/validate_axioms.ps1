#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  ADE Axiom Validation Script for Windows/PowerShell
.DESCRIPTION
  This script validates that the codebase adheres to ADE (Axiom-Driven
  Engineering) principles and invariants.
.EXAMPLE
  ./scripts/validate_axioms.ps1
#>

$ErrorActionPreference = 'Continue'

# UTF-8 Console output enforcement
if ($PSVersionTable.PSVersion.Major -ge 5) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}

$REPO_ROOT = Split-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) -Parent
$ERRORS = 0

function Pass {
    param([string]$Message)
    Write-Host "  [PASS] $Message" -ForegroundColor Green
}

function Fail {
    param([string]$Message)
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
    $script:ERRORS++
}

Write-Host "=== Starting ADE Axiom Validation ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# AXIOM 1: Required files must exist
# ============================================================================
Write-Host "--- A1: Required files ---" -ForegroundColor Cyan

$requiredFiles = @("README.md", "LICENSE", "AXIOMS.md")
foreach ($rf in $requiredFiles) {
    $filePath = Join-Path $REPO_ROOT $rf
    if (Test-Path -Path $filePath -PathType Leaf) {
        Pass "$rf exists"
    } else {
        Fail "$rf is missing"
    }
}

# ============================================================================
# AXIOM 2: Shell scripts must have a proper shebang
# ============================================================================
Write-Host ""
Write-Host "--- A2: Shell script shebangs ---" -ForegroundColor Cyan

$scriptsDir = Join-Path $REPO_ROOT "scripts"
$shScripts = Get-ChildItem -Path $scriptsDir -Filter "*.sh" -File -ErrorAction SilentlyContinue

foreach ($script in $shScripts) {
    $firstLine = Get-Content -Path $script.FullName -TotalCount 1 -ErrorAction SilentlyContinue
    if ($null -eq $firstLine) { $firstLine = "" }
    $firstLine = $firstLine.Trim()
    if ($firstLine -match '^#!/bin/(ba)?sh') {
        Pass "$($script.Name) has valid shebang: $firstLine"
    } else {
        Fail "$($script.Name) missing or invalid shebang (got: '$firstLine')"
    }
}

# ============================================================================
# AXIOM 3: Shell scripts must be executable in git
# ============================================================================
Write-Host ""
Write-Host "--- A3: Shell script permissions ---" -ForegroundColor Cyan

foreach ($script in $shScripts) {
    $name = $script.Name
    $relPath = "scripts/$name"
    # Query git ls-files
    $gitOut = git -C $REPO_ROOT ls-files -s $relPath 2>$null
    $mode = ""
    if ($gitOut -match '^\d+') {
        $mode = $Matches[0]
    }
    if ($mode -eq "100755") {
        Pass "$name is executable (mode $mode)"
    } else {
        $modeStr = if ($mode) { $mode } else { "unknown" }
        Fail "$name is NOT executable (mode: $modeStr)"
    }
}

# ============================================================================
# AXIOM 4: Workflow YAML files must be parseable
# ============================================================================
Write-Host ""
Write-Host "--- A4: Workflow YAML syntax ---" -ForegroundColor Cyan

$workflowDir = Join-Path $REPO_ROOT ".github\workflows"
if (Test-Path -Path $workflowDir -PathType Container) {
    $workflows = Get-ChildItem -Path $workflowDir -Include "*.yml", "*.yaml" -File -Recurse
    foreach ($wf in $workflows) {
        $name = $wf.Name
        $content = Get-Content -Path $wf.FullName -Raw
        
        # Basic YAML checks: tabs check
        if ($content -match "\t") {
            Fail "$name contains tab indentation (YAML requires spaces)"
        } elseif ($content -match "(?m)^jobs:") {
            Pass "$name is well-formed (has jobs: block, no tab indentation)"
        } else {
            Fail "$name is missing required 'jobs:' key"
        }
    }
} else {
    Fail "Workflow directory $workflowDir does not exist"
}

# ============================================================================
# AXIOM 6: Unresolved conflict markers must not exist
# ============================================================================
Write-Host ""
Write-Host "--- A6: Git conflict markers ---" -ForegroundColor Cyan

$unresolvedConflicts = @()
$scanExtensions = @("*.sh", "*.ps1", "*.md", "*.json", "*.yml", "*.yaml", "*.toml")
$excludeDirs = @(".git", ".bashunit", "node_modules", "lib")

$filesToScan = Get-ChildItem -Path $REPO_ROOT -File -Recurse | Where-Object {
    $file = $_
    $rel = $file.FullName.Replace($REPO_ROOT, "").TrimStart("\").TrimStart("/")
    
    # Exclude directories
    $exclude = $false
    foreach ($d in $excludeDirs) {
        if ($rel -match "^$d" -or $rel -match "[\\/]$d[\\/]") {
            $exclude = $true
            break
        }
    }
    
    # Check matching extension and ignore this file itself
    $matchExt = $false
    if (-not $exclude -and $file.Name -ne "validate_axioms.ps1" -and $file.Name -ne "validate_axioms.sh") {
        foreach ($ext in $scanExtensions) {
            if ($file.Name -like $ext) {
                $matchExt = $true
                break
            }
        }
    }
    $matchExt -and -not $exclude
}

foreach ($file in $filesToScan) {
    $lines = Get-Content -LiteralPath $file.FullName -ErrorAction SilentlyContinue
    if ($null -eq $lines) { continue }
    $lineNum = 1
    foreach ($line in $lines) {
        if ($line -match "^<<<<<<<" -or $line -match "^=======" -or $line -match "^>>>>>>>") {
            $unresolvedConflicts += "$($file.Name) at line $($lineNum): '$($line.Trim())'"
        }
        $lineNum++
    }
}

if ($unresolvedConflicts.Count -eq 0) {
    Pass "No unresolved git conflict markers found"
} else {
    Fail "Found unresolved conflict markers in the following file(s):"
    foreach ($c in $unresolvedConflicts) {
        Write-Host "    - $c" -ForegroundColor Yellow
    }
}

# ============================================================================
# AXIOM 7: All commits in the PR must be signed
# ============================================================================
Write-Host ""
Write-Host "--- A7: Commit signatures ---" -ForegroundColor Cyan

$gitCheck = git rev-parse --verify origin/main 2>$null
if ($null -ne $gitCheck) {
    $commitRange = "origin/main...HEAD"
} else {
    $commitRange = "HEAD~1..HEAD"
}

Write-Host "Checking commits in range: $commitRange"

$unsignedCommits = @()
$commitsOut = git log $commitRange --format="%H:%G?" 2>$null
if ($null -ne $commitsOut) {
    foreach ($line in $commitsOut) {
        if ($line -match '^([0-9a-fA-F]+):(.*)$') {
            $sha = $Matches[1]
            $sigStatus = $Matches[2]
            if ($sigStatus -eq "N") {
                $unsignedCommits += $sha
            }
        }
    }
}

if ($unsignedCommits.Count -eq 0) {
    Pass "All commits in branch are signed"
} else {
    Fail "The following commit(s) are UNSIGNED:"
    foreach ($sha in $unsignedCommits) {
        Write-Host "    - $sha" -ForegroundColor Yellow
    }
}

# ============================================================================
# AXIOM 8: Dual-Environment Compatibility
# ============================================================================
Write-Host ""
Write-Host "--- A8: Dual-Environment Script Parity ---" -ForegroundColor Cyan

$failedParity = $false

# 1. Check that every .sh has a .ps1
foreach ($script in $shScripts) {
    $ps1Path = $script.FullName -replace '\.sh$', '.ps1'
    if (Test-Path -Path $ps1Path -PathType Leaf) {
        Pass "$($script.Name) has matching .ps1"
    } else {
        Fail "$($script.Name) has NO matching .ps1 script"
        $failedParity = $true
    }
}

# 2. Check that every .ps1 has a .sh
$ps1Scripts = Get-ChildItem -Path $scriptsDir -Filter "*.ps1" -File -ErrorAction SilentlyContinue
foreach ($script in $ps1Scripts) {
    $shPath = $script.FullName -replace '\.ps1$', '.sh'
    if (Test-Path -Path $shPath -PathType Leaf) {
        Pass "$($script.Name) has matching .sh"
    } else {
        Fail "$($script.Name) has NO matching .sh script"
        $failedParity = $true
    }
}

# ============================================================================
# Summary
# ============================================================================
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
if ($ERRORS -gt 0) {
    Write-Host "  VALIDATION FAILED: $ERRORS error(s)" -ForegroundColor Red
    Write-Host "======================================" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host "  All ADE axioms validated successfully!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Cyan
    exit 0
}
