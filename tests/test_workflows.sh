#!/bin/bash

################################################################################
# TDD Test Suite: Workflow Validation
#
# Tests that all GitHub Actions workflow files are well-formed:
#   - No self-referencing reusable workflows (infinite loops)
#   - All workflows have an 'on:' trigger or 'workflow_call' declaration
#   - All 'uses:' references point to existing workflow files
################################################################################

set -e

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=""

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW_DIR="$REPO_ROOT/.github/workflows"

assert_pass() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "  ✅ PASS: $1"
}

assert_fail() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES="$FAILURES\n  ❌ FAIL: $1"
  echo "  ❌ FAIL: $1"
}

echo "🧪 Running Workflow Validation Tests..."
echo ""

##############################################################################
# TEST 1: No workflow references itself (self-referencing loop detection)
##############################################################################
echo "--- Test: No self-referencing workflows ---"

for workflow_file in "$WORKFLOW_DIR"/*.yml; do
  filename="$(basename "$workflow_file")"
  if grep -q "uses:.*workflows/${filename}@" "$workflow_file" 2>/dev/null; then
    assert_fail "$filename references itself — creates an infinite loop"
  else
    assert_pass "$filename does not self-reference"
  fi
done

##############################################################################
# TEST 2: All workflows have a trigger ('on:' block or 'workflow_call')
##############################################################################
echo ""
echo "--- Test: All workflows have a trigger ---"

for workflow_file in "$WORKFLOW_DIR"/*.yml; do
  filename="$(basename "$workflow_file")"
  if grep -qE "^on:" "$workflow_file" 2>/dev/null || grep -q "workflow_call" "$workflow_file" 2>/dev/null; then
    assert_pass "$filename has a trigger defined"
  else
    assert_fail "$filename has no 'on:' trigger or 'workflow_call' declaration"
  fi
done

##############################################################################
# TEST 3: All 'uses:' workflow references point to files that exist
##############################################################################
echo ""
echo "--- Test: All reusable workflow references resolve ---"

for workflow_file in "$WORKFLOW_DIR"/*.yml; do
  filename="$(basename "$workflow_file")"
  # Extract reusable workflow references like: First-ADE/.github/.github/workflows/X.yml@main
  refs=$(grep -oP 'uses:\s*First-ADE/\.github/\.github/workflows/\K[^@]+' "$workflow_file" 2>/dev/null || true)
  if [ -z "$refs" ]; then
    assert_pass "$filename has no internal reusable workflow refs to check"
  else
    for ref in $refs; do
      if [ -f "$WORKFLOW_DIR/$ref" ]; then
        assert_pass "$filename -> $ref exists"
      else
        assert_fail "$filename -> $ref does NOT exist"
      fi
    done
  fi
done

##############################################################################
# Summary
##############################################################################
echo ""
echo "======================================"
echo "  Tests Run:    $TESTS_RUN"
echo "  Passed:       $TESTS_PASSED"
echo "  Failed:       $TESTS_FAILED"
echo "======================================"

if [ "$TESTS_FAILED" -gt 0 ]; then
  echo ""
  echo "Failures:"
  echo -e "$FAILURES"
  exit 1
fi

echo ""
echo "✅ All workflow tests passed!"
exit 0
