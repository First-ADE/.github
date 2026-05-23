#!/bin/bash
################################################################################
# Constitution Review Script
#
# Feeds current repo context (axioms, structure, SpecKit template) to a local
# LLM via Ollama and asks it to propose a constitution for the project.
#
# Output: .specify/constitution.md (created or updated)
#
# Usage: ./scripts/review_constitution.sh
# Requires: ollama running with qwen2.5-coder:3b pulled
################################################################################

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONSTITUTION_FILE="$REPO_ROOT/.specify/constitution.md"
AXIOMS_FILE="$REPO_ROOT/AXIOMS.md"
TEMPLATE_FILE="$REPO_ROOT/.specify/templates/constitution-template.md"
MODEL="qwen2.5-coder:3b"

echo "🔍 Gathering repo context..."

# --- Collect context ---

# 1. Current axioms
AXIOMS_CONTENT=""
if [ -f "$AXIOMS_FILE" ]; then
  AXIOMS_CONTENT=$(cat "$AXIOMS_FILE")
fi

# 2. Repo file tree (depth 3, no hidden except .github/workflows)
TREE=$(find "$REPO_ROOT" -maxdepth 3 \
  \( -name ".git" -o -name "node_modules" -o -name "lib" -o -name ".specify" -o -name ".gemini" \) -prune \
  -o -type f -print | sed "s|$REPO_ROOT/||" | sort)

# 3. Current constitution (if exists)
EXISTING_CONSTITUTION=""
if [ -f "$CONSTITUTION_FILE" ]; then
  EXISTING_CONSTITUTION=$(cat "$CONSTITUTION_FILE")
fi

# 4. Constitution template
TEMPLATE_CONTENT=""
if [ -f "$TEMPLATE_FILE" ]; then
  TEMPLATE_CONTENT=$(cat "$TEMPLATE_FILE")
fi

# 5. README
README_CONTENT=""
if [ -f "$REPO_ROOT/README.md" ]; then
  README_CONTENT=$(cat "$REPO_ROOT/README.md")
fi

# --- Build prompt ---

PROMPT="You are a software architect reviewing an organization's .github repository for the First-ADE organization. Your task is to write or revise the project constitution following the SpecKit constitution template format.

## Current Repository Structure
\`\`\`
$TREE
\`\`\`

## README.md
$README_CONTENT

## Current Axioms (AXIOMS.md)
$AXIOMS_CONTENT

## Existing Constitution
$EXISTING_CONSTITUTION

## Constitution Template Format
$TEMPLATE_CONTENT

## Instructions

Based on the repository context above, write a complete constitution for this .github repository following the template format. The constitution should:

1. Define 5-7 core principles that align with the existing axioms (A1-A4)
2. Include ADE (Axiom-Driven Engineering) methodology as a foundational principle
3. Include TDD (Test-Driven Development) as a non-negotiable principle
4. Define governance rules for how axioms and the constitution can be amended
5. Use concrete, testable language (MUST, MUST NOT, SHOULD)
6. Reference the actual tools in use (bashunit, SpecKit, GitHub Actions)

If an existing constitution is provided, propose targeted improvements rather than rewriting from scratch. Mark additions with [NEW] and revisions with [REVISED].

Output ONLY the constitution markdown content, nothing else. No explanations before or after."

echo "🤖 Sending to $MODEL via Ollama..."

# --- Call Ollama ---
RESPONSE=$(ollama run "$MODEL" "$PROMPT" 2>/dev/null)

if [ -z "$RESPONSE" ]; then
  echo "❌ Model returned empty response"
  exit 1
fi

echo "✅ Received response ($(echo "$RESPONSE" | wc -l) lines)"

# --- Write output ---
echo "$RESPONSE" > "$CONSTITUTION_FILE"

echo "📄 Constitution written to $CONSTITUTION_FILE"
echo ""
echo "--- Preview (first 20 lines) ---"
head -n 20 "$CONSTITUTION_FILE"
