#!/bin/bash

################################################################################
# ADE Axiom Validation Script
#
# Validates that a repository adheres to the First-ADE axioms (see AXIOMS.md).
# Every block below names the axiom it enforces; AXIOMS.md must list the same
# set. A block without an entry, or an entry without a block, is a violation.
#
# Axioms enforced:
#   A1: Required files (README.md, LICENSE; AXIOMS.md in the .github repo)
#   A2: Shell scripts in scripts/ have a proper shebang
#   A3: Shell scripts in scripts/ are executable in git
#   A4: Workflow YAML files are well-formed
#   A5: CI must pass before merge (enforced by branch protection, not here)
#   A6: No unresolved git conflict markers
#   A7: Commits on the branch under review are signed
#   A8: LICENSE is MIT with holder Brandon Fox; README has an Independence section
#   A9: README line 1 is a level-one heading; a Status line follows within 10 lines
#
# Usage: ./scripts/validate_axioms.sh
#        ADE_REPO_ROOT=/path/to/other/repo ./scripts/validate_axioms.sh
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SELF_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="${ADE_REPO_ROOT:-$SELF_ROOT}"
ERRORS=0

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; ERRORS=$((ERRORS + 1)); }

echo "Starting ADE Axiom Validation in $REPO_ROOT"
echo ""

##############################################################################
# AXIOM 1: Required files must exist
##############################################################################
echo "--- A1: Required files ---"

REQUIRED="README.md LICENSE"
if [ "$REPO_ROOT" = "$SELF_ROOT" ]; then
  REQUIRED="$REQUIRED AXIOMS.md"
fi
for required_file in $REQUIRED; do
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
    if grep -Pn '^\t' "$wf" > /dev/null 2>&1; then
      fail "$name contains tab indentation (YAML requires spaces)"
    elif grep -q '^jobs:' "$wf" 2>/dev/null; then
      pass "$name is well-formed (has jobs: block, no tab indentation)"
    else
      fail "$name is missing required 'jobs:' key"
    fi
  done
else
  pass "No workflow directory; nothing to check"
fi

##############################################################################
# AXIOM 5: CI must pass before merge
##############################################################################
echo ""
echo "--- A5: CI before merge ---"
pass "Enforced by branch protection on main (not checkable from inside a run)"

##############################################################################
# AXIOM 6: Unresolved conflict markers must not exist
##############################################################################
echo ""
echo "--- A6: Git conflict markers ---"

CONFLICT_FILES=$(grep -rnwlE '^<<<<<<<|^>>>>>>>' "$REPO_ROOT" --exclude-dir={.git,.bashunit,node_modules,lib,.venv} --exclude="validate_axioms.sh" --exclude="AXIOMS.md" 2>/dev/null || true)
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

if git -C "$REPO_ROOT" rev-parse --verify origin/main >/dev/null 2>&1; then
  COMMIT_RANGE="origin/main...HEAD"
else
  COMMIT_RANGE="HEAD~1..HEAD"
fi

echo "Checking commits in range: $COMMIT_RANGE"
UNSIGNED_COMMITS=""
# A signature is present when the commit object carries a gpgsig header (GPG or
# SSH). Verifying it against a key is GitHub's job; a CI runner has no keyring.
for sha in $(git -C "$REPO_ROOT" log "$COMMIT_RANGE" --format="%H" 2>/dev/null || true); do
  if ! git -C "$REPO_ROOT" cat-file commit "$sha" | grep -q '^gpgsig'; then
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
# AXIOM 8: LICENSE holder and Independence section
##############################################################################
echo ""
echo "--- A8: Independence and license holder ---"

if [ -f "$REPO_ROOT/LICENSE" ]; then
  if grep -q '^MIT License' "$REPO_ROOT/LICENSE" && grep -qE '^Copyright \(c\) [0-9]{4} Brandon Fox\s*$' "$REPO_ROOT/LICENSE"; then
    pass "LICENSE is MIT with holder Brandon Fox"
  else
    fail "LICENSE must be MIT with a line 'Copyright (c) <year> Brandon Fox'"
  fi
else
  fail "LICENSE missing (also A1)"
fi

if [ -f "$REPO_ROOT/README.md" ]; then
  if grep -qE '^## Independence' "$REPO_ROOT/README.md"; then
    pass "README.md has an Independence section"
  else
    fail "README.md is missing a '## Independence' section"
  fi
fi

##############################################################################
# AXIOM 9: README states what the project is and its status
##############################################################################
echo ""
echo "--- A9: README first line and status ---"

if [ -f "$REPO_ROOT/README.md" ]; then
  first=$(head -n 1 "$REPO_ROOT/README.md" | tr -d '\r')
  if echo "$first" | grep -qE '^# '; then
    pass "README.md line 1 is a level-one heading"
  else
    fail "README.md line 1 must be a level-one heading (got: '$first')"
  fi
  if sed -n '2,11p' "$REPO_ROOT/README.md" | tr -d '\r' | grep -qE '^> \*\*Status:\*\*'; then
    pass "README.md states a Status within the first 10 lines after the title"
  else
    fail "README.md must contain a line starting '> **Status:**' within lines 2-11"
  fi
fi

##############################################################################
# Summary
##############################################################################
echo ""
echo "======================================"
if [ "$ERRORS" -gt 0 ]; then
  echo "  VALIDATION FAILED: $ERRORS error(s)"
  echo "======================================"
  exit 1
else
  echo "  All ADE axioms validated successfully"
  echo "======================================"
  exit 0
fi
