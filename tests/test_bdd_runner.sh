#!/bin/bash

################################################################################
# TDD Test Suite: run_bdd_tests.sh Verification
#
# Tests that run_bdd_tests.sh performs REAL BDD testing, not just echoes.
# A valid BDD test runner must:
#   1. Have real logic beyond echo stubs
#   2. Reference and process .feature files
#   3. Have failure exit paths (exit non-zero when tests fail)
#   4. Execute feature files and report results
#   5. Pass when run against a repo with valid features
################################################################################

set -e

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=""

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/run_bdd_tests.sh"

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

echo "🧪 Running run_bdd_tests.sh Verification Tests..."
echo ""

##############################################################################
# TEST 1: Script must NOT be a no-op stub
##############################################################################
echo "--- Test: Script has real logic ---"

real_lines=$(grep -cvE '^\s*$|^\s*#|^\s*echo |^\s*set |^\s*exit ' "$SCRIPT" 2>/dev/null || echo "0")

if [ "$real_lines" -gt 3 ]; then
  assert_pass "Script has $real_lines lines of real logic"
else
  assert_fail "Script has only $real_lines lines of real logic — likely a stub"
fi

##############################################################################
# TEST 2: Script must reference .feature files
##############################################################################
echo ""
echo "--- Test: Script processes feature files ---"

if grep -qE '\.feature|features/' "$SCRIPT" 2>/dev/null; then
  assert_pass "Script references .feature files or features/ directory"
else
  assert_fail "Script does not reference any .feature files"
fi

##############################################################################
# TEST 3: Script must have failure exit paths
##############################################################################
echo ""
echo "--- Test: Script can exit non-zero on failure ---"

if grep -qE 'exit 1|exit \$|FAILED=|failed=|ERRORS=|errors=' "$SCRIPT" 2>/dev/null; then
  assert_pass "Script has failure exit paths"
else
  assert_fail "Script always exits 0 — no failure detection"
fi

##############################################################################
# TEST 4: Feature files must exist for the runner to consume
##############################################################################
echo ""
echo "--- Test: Feature files exist ---"

feature_count=$(find "$REPO_ROOT/features" -name "*.feature" 2>/dev/null | wc -l)

if [ "$feature_count" -gt 0 ]; then
  assert_pass "Found $feature_count .feature file(s) in features/"
else
  assert_fail "No .feature files found in features/"
fi

##############################################################################
# TEST 5: Script passes when run against valid features
##############################################################################
echo ""
echo "--- Test: Script passes on valid repo ---"

output=$("$SCRIPT" 2>&1)
exit_code=$?

if [ "$exit_code" -eq 0 ]; then
  assert_pass "Script exits 0 on valid repo (exit code: $exit_code)"
else
  assert_fail "Script exits $exit_code on valid repo — should pass"
fi

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
echo "✅ All run_bdd_tests.sh tests passed!"
exit 0
