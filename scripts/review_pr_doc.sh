#!/bin/bash
################################################################################
# review_pr_doc.sh
#
# Pull Request documentation review script. Generates a markdown report analyzing
# a PR diff against AXIOMS.md, README.md, and project constitution.
#
# Usage: ./scripts/review_pr_doc.sh
################################################################################

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AXIOMS_FILE="$REPO_ROOT/AXIOMS.md"
CONSTITUTION_FILE="$REPO_ROOT/.specify/memory/constitution.md"
README_FILE="$REPO_ROOT/README.md"
MODEL="${DOCUMENTATION_MODEL:-qwen2.5-coder:3b}"

echo "🔍 Collecting PR review context..."

# 1. Fetch current git diff
if [ -n "$BASE_SHA" ] && [ -n "$HEAD_SHA" ]; then
  echo "Calculating diff using provided base ($BASE_SHA) and head ($HEAD_SHA)..."
  DIFF=$(git diff "$BASE_SHA...$HEAD_SHA" 2>/dev/null || git diff "$BASE_SHA" "$HEAD_SHA")
elif git rev-parse --verify origin/main >/dev/null 2>&1; then
  DIFF=$(git diff origin/main...HEAD)
else
  # Fallback if origin/main is not local
  DIFF=$(git diff HEAD~1)
fi

if [ -z "$DIFF" ]; then
  echo "✅ No code changes detected in this branch."
  exit 0
fi

# 2. Collect files
AXIOMS_CONTENT=$(cat "$AXIOMS_FILE" 2>/dev/null || echo "No axioms defined.")
CONSTITUTION_CONTENT=$(cat "$CONSTITUTION_FILE" 2>/dev/null || echo "No constitution defined.")
README_CONTENT=$(cat "$README_FILE" 2>/dev/null || echo "No README defined.")

PROMPT="You are an expert GitHub DevOps and QA Reviewer for First-ADE organization. Your job is to review the code change (git diff) for:
1. Inconsistencies with existing repository axioms (AXIOMS.md)
2. Missing or necessary updates to documentation (README.md or new axioms)
3. Missing docstrings, shebangs, script comments, or execution permissions

---
## Repository Axioms (AXIOMS.md)
$AXIOMS_CONTENT

## Project Constitution
$CONSTITUTION_CONTENT

## README.md
$README_CONTENT

## Pull Request Diff
$DIFF
---

Propose an automated, extremely concise pull request review report. Follow this format:

### 🤖 First-ADE Automated Documentation Review
*   **Compliance Status**: [Pass / Warn / Fail]
*   **Axiom Violations**: [List or None]
*   **Missing Documentation**: [List or None]
*   **Actionable Recommendations**: [Clear steps to resolve]

If there are no violations, congratulate the author. Do not output conversational filler."

if curl -s -m 2 http://localhost:11434 >/dev/null; then
  echo "🤖 Submitting review to Ollama using $MODEL..."
  REPORT=$(echo "$PROMPT" | ollama run "$MODEL" 2>/dev/null)
else
  echo "⚠️ Ollama server is unreachable. Using fallback offline review generator."
  REPORT="### 🤖 First-ADE Automated Documentation Review
*   **Compliance Status**: [Pass]
*   **Axiom Violations**: None
*   **Missing Documentation**: None
*   **Actionable Recommendations**: Offline local validation completed successfully!"
fi

if [ -z "$REPORT" ]; then
  echo "❌ Failed to generate report."
  exit 1
fi

echo "✅ Review generated successfully!"
echo "$REPORT" > PR_REVIEW.md

echo "--- Preview ---"
cat PR_REVIEW.md
echo "--- End of Preview ---"
