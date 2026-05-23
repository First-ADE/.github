#!/bin/bash

################################################################################
# ADE Axiom Validation Script
#
# This script validates that the codebase adheres to ADE (Axiom-Driven
# Engineering) principles and invariants.
#
# Axioms enforced:
#   A1: Required files (README.md, LICENSE) must exist
#   A2: All shell scripts must have a proper shebang (#!/bin/bash)
#   A3: All shell scripts must be executable in git
#   A4: All workflow YAML files must be syntactically valid
#   A5: All CI checks must pass before merge (enforced by branch protection)
#
# Usage: ./scripts/validate_axioms.sh
################################################################################

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

pass() { echo "  ✅ PASS: $1"; }
fail() { echo "  ❌ FAIL: $1"; ERRORS=$((ERRORS + 1)); }

echo "🔍 Starting ADE Axiom Validation..."
echo ""

##############################################################################
# AXIOM 1: Required files must exist
##############################################################################
echo "--- A1: Required files ---"

for required_file in README.md LICENSE AXIOMS.md; do
  if [ -f "$REPO_ROOT/$required_file" ]; then
    pass "$required_file exists"
  else
    fail "$required_file is missing"
  fi
done

##############################################################################
# AXIOM 2: Shell scripts must have a proper shebang
##############################################################################
echo ""
echo "--- A2: Shell script shebangs ---"

for script in "$REPO_ROOT"/scripts/*.sh; do
  [ -f "$script" ] || continue
  name="$(basename "$script")"
  first_line=$(head -n 1 "$script" | tr -d '\r')
  if echo "$first_line" | grep -qE '^#!/bin/(ba)?sh'; then
    pass "$name has valid shebang: $first_line"
  else
    fail "$name missing or invalid shebang (got: '$first_line')"
  fi
done

##############################################################################
# AXIOM 3: Shell scripts must be executable in git
##############################################################################
echo ""
echo "--- A3: Shell script permissions ---"

for script in "$REPO_ROOT"/scripts/*.sh; do
  [ -f "$script" ] || continue
  name="$(basename "$script")"
  rel_path="scripts/$name"
  mode=$(git -C "$REPO_ROOT" ls-files -s "$rel_path" 2>/dev/null | awk '{print $1}')
  if [ "$mode" = "100755" ]; then
    pass "$name is executable (mode $mode)"
  else
    fail "$name is NOT executable (mode: ${mode:-unknown})"
  fi
done

##############################################################################
# AXIOM 4: Workflow YAML files must be parseable
##############################################################################
echo ""
echo "--- A4: Workflow YAML syntax ---"

WORKFLOW_DIR="$REPO_ROOT/.github/workflows"
if [ -d "$WORKFLOW_DIR" ]; then
  for wf in "$WORKFLOW_DIR"/*.yml "$WORKFLOW_DIR"/*.yaml; do
    [ -f "$wf" ] || continue
    name="$(basename "$wf")"
    # Basic YAML validation: check for tabs (YAML forbids tabs for indentation)
    if grep -Pn '^\t' "$wf" > /dev/null 2>&1; then
      fail "$name contains tab indentation (YAML requires spaces)"
    # Check for basic structure: must contain 'jobs:' key
    elif grep -q '^jobs:' "$wf" 2>/dev/null; then
      pass "$name is well-formed (has jobs: block, no tab indentation)"
    else
      fail "$name is missing required 'jobs:' key"
    fi
  done
else
  fail "Workflow directory $WORKFLOW_DIR does not exist"
fi

##############################################################################
# AXIOM 6: Unresolved conflict markers must not exist
##############################################################################
echo ""
echo "--- A6: Git conflict markers ---"

CONFLICT_FILES=$(grep -rnwlE '^<<<<<<<|^>>>>>>>' "$REPO_ROOT" --exclude-dir={.git,.bashunit,node_modules,lib} --exclude="validate_axioms.sh" 2>/dev/null || true)
if [ -z "$CONFLICT_FILES" ]; then
  pass "No unresolved git conflict markers found"
else
  fail "Found unresolved conflict markers in the following file(s):"
  for f in $CONFLICT_FILES; do
    echo "    - $f"
  done
fi

##############################################################################
# AXIOM 7: All commits in the PR must be signed
##############################################################################
echo ""
echo "--- A7: Commit signatures ---"

if git rev-parse --verify origin/main >/dev/null 2>&1; then
  COMMIT_RANGE="origin/main...HEAD"
else
  COMMIT_RANGE="HEAD~1..HEAD"
fi

echo "Checking commits in range: $COMMIT_RANGE"
UNSIGNED_COMMITS=""
for commit_data in $(git log "$COMMIT_RANGE" --format="%H:%G?" 2>/dev/null || true); do
  sha=$(echo "$commit_data" | cut -d: -f1)
  sig_status=$(echo "$commit_data" | cut -d: -f2)
  if [ "$sig_status" = "N" ]; then
    UNSIGNED_COMMITS="$UNSIGNED_COMMITS $sha"
  fi
done

if [ -z "$UNSIGNED_COMMITS" ]; then
  pass "All commits in branch are signed"
else
  fail "The following commit(s) are UNSIGNED:"
  for sha in $UNSIGNED_COMMITS; do
    echo "    - $sha"
  done
fi

##############################################################################
# Summary
##############################################################################
echo ""
echo "======================================"
if [ "$ERRORS" -gt 0 ]; then
  echo "  ❌ VALIDATION FAILED: $ERRORS error(s)"
  echo "======================================"
  exit 1
else
  echo "  ✅ All ADE axioms validated successfully!"
  echo "======================================"
  exit 0
fi
