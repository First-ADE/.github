#!/usr/bin/env pwsh
<#!
.SYNOPSIS
  Constitution Review Script for Windows/PowerShell
.DESCRIPTION
  Feeds current repo context (axioms, structure, SpecKit template) to a local
  LLM via Ollama and asks it to propose a constitution for the project.
.EXAMPLE
  ./scripts/review_constitution.ps1
#>

$ErrorActionPreference = 'Stop'

# UTF-8 Console output enforcement
if ($PSVersionTable.PSVersion.Major -ge 5) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}

$REPO_ROOT = Split-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) -Parent
$CONSTITUTION_FILE = Join-Path $REPO_ROOT ".specify\constitution.md"
$AXIOMS_FILE = Join-Path $REPO_ROOT "AXIOMS.md"
$TEMPLATE_FILE = Join-Path $REPO_ROOT ".specify\templates\constitution-template.md"
$MODEL = "qwen2.5-coder:3b"

Write-Host "🔍 Gathering repo context..." -ForegroundColor Cyan

# --- Collect context ---

# 1. Current axioms
$axiomsContent = ""
if (Test-Path -Path $AXIOMS_FILE -PathType Leaf) {
    $axiomsContent = Get-Content -Path $AXIOMS_FILE -Raw
}

# 2. Repo file tree (depth 3, excluding build/node_modules/etc)
Write-Host "Generating repository structure..." -ForegroundColor Cyan
$excludeDirs = @(".git", "node_modules", "lib", ".specify", ".gemini", ".bashunit")
$treeLines = @()

$items = Get-ChildItem -Path $REPO_ROOT -Recurse | Where-Object {
    $item = $_
    $rel = $item.FullName.Replace($REPO_ROOT, "").TrimStart("\").TrimStart("/")
    
    # Prune excluded directories
    $prune = $false
    foreach ($d in $excludeDirs) {
        if ($rel -match "^$d" -or $rel -match "[\\/]$d[\\/]") {
            $prune = $true
            break
        }
    }
    
    # Limit depth to 3
    $depth = ($rel -split '[\\/]').Count
    
    -not $prune -and $depth -le 3 -and -not $item.PSIsContainer
} | Sort-Object FullName

foreach ($item in $items) {
    $rel = $item.FullName.Replace($REPO_ROOT, "").TrimStart("\").TrimStart("/")
    $treeLines += $rel
}
$tree = $treeLines -join "`n"

# 3. Current constitution (if exists)
$existingConstitution = ""
if (Test-Path -Path $CONSTITUTION_FILE -PathType Leaf) {
    $existingConstitution = Get-Content -Path $CONSTITUTION_FILE -Raw
}

# 4. Constitution template
$templateContent = ""
if (Test-Path -Path $TEMPLATE_FILE -PathType Leaf) {
    $templateContent = Get-Content -Path $TEMPLATE_FILE -Raw
}

# 5. README
$readmeContent = ""
$readmeFile = Join-Path $REPO_ROOT "README.md"
if (Test-Path -Path $readmeFile -PathType Leaf) {
    $readmeContent = Get-Content -Path $readmeFile -Raw
}

# --- Build prompt ---
$prompt = @"
You are a software architect reviewing an organization's .github repository for the First-ADE organization. Your task is to write or revise the project constitution following the SpecKit constitution template format.

## Current Repository Structure
\`\`\`
$tree
\`\`\`

## README.md
$readmeContent

## Current Axioms (AXIOMS.md)
$axiomsContent

## Existing Constitution
$existingConstitution

## Constitution Template Format
$templateContent

## Instructions

Based on the repository context above, write a complete constitution for this .github repository following the template format. The constitution should:

1. Define 5-7 core principles that align with the existing axioms (A1-A4)
2. Include ADE (Axiom-Driven Engineering) methodology as a foundational principle
3. Include TDD (Test-Driven Development) as a non-negotiable principle
4. Define governance rules for how axioms and the constitution can be amended
5. Use concrete, testable language (MUST, MUST NOT, SHOULD)
6. Reference the actual tools in use (bashunit, SpecKit, GitHub Actions)

If an existing constitution is provided, propose targeted improvements rather than rewriting from scratch. Mark additions with [NEW] and revisions with [REVISED].

Output ONLY the constitution markdown content, nothing else. No explanations before or after.
"@

# --- Call Ollama ---
$ollamaOnline = $false
try {
    $req = Invoke-WebRequest -Uri "http://localhost:11434" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($req.StatusCode -eq 200) {
        $ollamaOnline = $true
    }
} catch {}

if (-not $ollamaOnline) {
    Write-Host "❌ Ollama server is unreachable. Cannot execute constitution review (requires Ollama qwen2.5-coder:3b)." -ForegroundColor Red
    exit 1
}

Write-Host "🤖 Sending to $MODEL via Ollama..." -ForegroundColor Gray
$responseContent = ""
try {
    $payload = @{
        model = $MODEL
        prompt = $prompt
        stream = $false
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 120
    $responseContent = $response.response
} catch {
    Write-Host "❌ Failed to generate response from Ollama: $_" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($responseContent)) {
    Write-Host "❌ Model returned empty response" -ForegroundColor Red
    exit 1
}

$linesCount = ($responseContent -split "`n").Count
Write-Host "✅ Received response ($linesCount lines)" -ForegroundColor Green

# Ensure specify directory exists
$specifyDir = Split-Path $CONSTITUTION_FILE -Parent
if (-not (Test-Path -Path $specifyDir -PathType Container)) {
    New-Item -Path $specifyDir -ItemType Directory | Out-Null
}

# --- Write output ---
$responseContent | Out-File -FilePath $CONSTITUTION_FILE -Encoding utf8

Write-Host "📄 Constitution written to $CONSTITUTION_FILE" -ForegroundColor Green
Write-Host ""
Write-Host "--- Preview (first 20 lines) ---" -ForegroundColor Cyan
Get-Content -Path $CONSTITUTION_FILE -TotalCount 20
Write-Host "--- End of Preview ---" -ForegroundColor Cyan
exit 0
