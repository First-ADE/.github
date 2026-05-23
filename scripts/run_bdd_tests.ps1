#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  BDD Test Runner Script for Windows/PowerShell
.DESCRIPTION
  A lightweight, native PowerShell BDD runner that parses Gherkin .feature files
  and executes step definitions defined in this script.
.EXAMPLE
  ./scripts/run_bdd_tests.ps1
#>

$ErrorActionPreference = 'Stop'

# UTF-8 Console output enforcement
if ($PSVersionTable.PSVersion.Major -ge 5) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}

$REPO_ROOT = Split-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) -Parent
$FEATURES_DIR = Join-Path $REPO_ROOT "features"

$SCENARIOS_RUN = 0
$SCENARIOS_PASSED = 0
$SCENARIOS_FAILED = 0
$STEPS_RUN = 0
$STEPS_PASSED = 0
$STEPS_FAILED = 0
$ERRORS = 0
$CONTEXT_DIR = ""

function Pass-Step {
    param([string]$Message)
    $script:STEPS_RUN++
    $script:STEPS_PASSED++
    Write-Host "      [PASS] $Message" -ForegroundColor Green
}

function Fail-Step {
    param([string]$Message)
    $script:STEPS_RUN++
    $script:STEPS_FAILED++
    $script:ERRORS++
    Write-Host "      [FAIL] $Message" -ForegroundColor Red
}

# --- Step Definitions ---

function Step-Given-Repo-Root {
    $script:CONTEXT_DIR = $REPO_ROOT
    Pass-Step "Given the repository root directory"
}

function Step-Given-Scripts-Dir {
    param([string]$Dir)
    $script:CONTEXT_DIR = Join-Path $REPO_ROOT $Dir
    if (Test-Path -Path $script:CONTEXT_DIR -PathType Container) {
        Pass-Step "Given the scripts in `"$Dir`" directory"
    } else {
        Fail-Step "Given the scripts in `"$Dir`" directory -- directory not found"
    }
}

function Step-Then-File-Exists {
    param([string]$Filename)
    $filePath = Join-Path $script:CONTEXT_DIR $Filename
    if (Test-Path -Path $filePath -PathType Leaf) {
        Pass-Step "Then the file `"$Filename`" should exist"
    } else {
        Fail-Step "Then the file `"$Filename`" should exist -- NOT FOUND"
    }
}

function Step-Then-Dir-Exists {
    param([string]$Dirname)
    $dirPath = Join-Path $script:CONTEXT_DIR $Dirname
    if (Test-Path -Path $dirPath -PathType Container) {
        Pass-Step "Then the directory `"$Dirname`" should exist"
    } else {
        Fail-Step "Then the directory `"$Dirname`" should exist -- NOT FOUND"
    }
}

function Step-Then-Shebang {
    $failed = $false
    $shFiles = Get-ChildItem -Path $script:CONTEXT_DIR -Filter "*.sh" -File -ErrorAction SilentlyContinue
    foreach ($script in $shFiles) {
        # Read first line
        $firstLine = Get-Content -Path $script.FullName -TotalCount 1 -ErrorAction SilentlyContinue
        if ($null -eq $firstLine) { $firstLine = "" }
        $firstLine = $firstLine.Trim()
        if ($firstLine -match '^#!/bin/(ba)?sh') {
            # valid shebang
        } else {
            Fail-Step "Then $($script.Name) should start with a shebang -- got '$firstLine'"
            $failed = $true
        }
    }
    if (-not $failed) {
        Pass-Step "Then every `".sh`" file should start with a shebang line"
    }
}

function Step-Then-Executable {
    $failed = $false
    $shFiles = Get-ChildItem -Path $script:CONTEXT_DIR -Filter "*.sh" -File -ErrorAction SilentlyContinue
    foreach ($script in $shFiles) {
        $name = $script.Name
        $rel = "scripts/$name"
        # Run git command to get permissions
        $gitOut = git -C $REPO_ROOT ls-files -s $rel 2>$null
        $mode = ""
        if ($gitOut -match '^\d+') {
            $mode = $Matches[0]
        }
        if ($mode -eq "100755") {
            # valid executable permission in git
        } else {
            Fail-Step "Then $name should be executable -- mode is ${mode}"
            $failed = $true
        }
    }
    if (-not $failed) {
        Pass-Step "Then every `".sh`" file should be executable in git"
    }
}

function Step-Then-Sh-Has-Ps1 {
    $failed = $false
    $shFiles = Get-ChildItem -Path $script:CONTEXT_DIR -Filter "*.sh" -File -ErrorAction SilentlyContinue
    foreach ($script in $shFiles) {
        $ps1Path = $script.FullName -replace '\.sh$', '.ps1'
        if (Test-Path -Path $ps1Path -PathType Leaf) {
            # valid
        } else {
            Fail-Step "Then $($script.Name) should have a corresponding .ps1 script -- NOT FOUND"
            $failed = $true
        }
    }
    if (-not $failed) {
        Pass-Step "Then every `".sh`" file should have a corresponding `".ps1`" script"
    }
}

function Step-Then-Ps1-Has-Sh {
    $failed = $false
    $ps1Files = Get-ChildItem -Path $script:CONTEXT_DIR -Filter "*.ps1" -File -ErrorAction SilentlyContinue
    foreach ($script in $ps1Files) {
        $shPath = $script.FullName -replace '\.ps1$', '.sh'
        if (Test-Path -Path $shPath -PathType Leaf) {
            # valid
        } else {
            Fail-Step "Then $($script.Name) should have a corresponding .sh script -- NOT FOUND"
            $failed = $true
        }
    }
    if (-not $failed) {
        Pass-Step "Then every `".ps1`" file should have a corresponding `".sh`" script"
    }
}

# --- Gherkin Parser & Runner ---

function Run-Feature-File {
    param([string]$FeatureFile)
    
    $inScenario = $false
    $scenarioFailed = $false
    
    Write-Host ""
    Write-Host "Feature file: $(Split-Path $FeatureFile -Leaf)" -ForegroundColor Cyan
    
    $lines = Get-Content -Path $FeatureFile
    foreach ($rawLine in $lines) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrEmpty($line) -or $line.StartsWith("#")) {
            continue
        }
        
        switch -Regex ($line) {
            "^Feature:\s*(.*)" {
                $featureName = $Matches[1]
                Write-Host "  Feature: $featureName" -ForegroundColor Yellow
            }
            "^Scenario:\s*(.*)" {
                # Close previous scenario
                if ($inScenario) {
                    $script:SCENARIOS_RUN++
                    if ($scenarioFailed) {
                        $script:SCENARIOS_FAILED++
                    } else {
                        $script:SCENARIOS_PASSED++
                    }
                }
                $scenarioName = $Matches[1]
                Write-Host ""
                Write-Host "    Scenario: $scenarioName" -ForegroundColor Yellow
                $inScenario = $true
                $scenarioFailed = $false
            }
            "^Given the repository root directory" {
                Step-Given-Repo-Root
            }
            "^Given the scripts in `"(.*)`" directory" {
                $dir = $Matches[1]
                Step-Given-Scripts-Dir -Dir $dir
            }
            "^Then the file `"(.*)`" should exist" {
                $file = $Matches[1]
                $oldErrors = $script:ERRORS
                Step-Then-File-Exists -Filename $file
                if ($script:ERRORS -gt $oldErrors) { $scenarioFailed = $true }
            }
            "^Then the directory `"(.*)`" should exist" {
                $dir = $Matches[1]
                $oldErrors = $script:ERRORS
                Step-Then-Dir-Exists -Dirname $dir
                if ($script:ERRORS -gt $oldErrors) { $scenarioFailed = $true }
            }
            "^Then every `"\.sh`" file should start with a shebang line" {
                $oldErrors = $script:ERRORS
                Step-Then-Shebang
                if ($script:ERRORS -gt $oldErrors) { $scenarioFailed = $true }
            }
            "^Then every `"\.sh`" file should be executable in git" {
                $oldErrors = $script:ERRORS
                Step-Then-Executable
                if ($script:ERRORS -gt $oldErrors) { $scenarioFailed = $true }
            }
            "^Then every `"\.sh`" file should have a corresponding `"\.ps1`" script" {
                $oldErrors = $script:ERRORS
                Step-Then-Sh-Has-Ps1
                if ($script:ERRORS -gt $oldErrors) { $scenarioFailed = $true }
            }
            "^Then every `"\.ps1`" file should have a corresponding `"\.sh`" script" {
                $oldErrors = $script:ERRORS
                Step-Then-Ps1-Has-Sh
                if ($script:ERRORS -gt $oldErrors) { $scenarioFailed = $true }
            }
            "^(As\s.*|I\sneed\s.*|I\swant\s.*|So\sthat\s.*)" {
                # Narrative lines, skip
            }
            Default {
                Write-Host "      [WARN] Undefined step: $line" -ForegroundColor Gray
            }
        }
    }
    
    # Close last scenario
    if ($inScenario) {
        $script:SCENARIOS_RUN++
        if ($scenarioFailed) {
            $script:SCENARIOS_FAILED++
        } else {
            $script:SCENARIOS_PASSED++
        }
    }
}

# --- Main Run ---

Write-Host "Starting Windows/PowerShell BDD Test Execution..." -ForegroundColor Cyan

if (-not (Test-Path -Path $FEATURES_DIR -PathType Container)) {
    Write-Host "FAILED: No features/ directory found at $FEATURES_DIR" -ForegroundColor Red
    exit 1
}

$featureFiles = Get-ChildItem -Path $FEATURES_DIR -Filter "*.feature" | Sort-Object Name

if ($null -eq $featureFiles -or $featureFiles.Count -eq 0) {
    Write-Host "FAILED: No .feature files found in $FEATURES_DIR" -ForegroundColor Red
    exit 1
}

foreach ($f in $featureFiles) {
    Run-Feature-File -FeatureFile $f.FullName
}

Write-Host "" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Scenarios: $SCENARIOS_RUN ($SCENARIOS_PASSED passed, $SCENARIOS_FAILED failed)" -ForegroundColor Cyan
Write-Host "  Steps:     $STEPS_RUN ($STEPS_PASSED passed, $STEPS_FAILED failed)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

if ($script:ERRORS -gt 0) {
    Write-Host ""
    Write-Host "FAILED: $script:ERRORS BDD test failure(s)!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "SUCCESS: All BDD tests passed!" -ForegroundColor Green
exit 0
