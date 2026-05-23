#!/bin/bash

################################################################################
# TDD Test Suite: validate_axioms.sh Verification
#
# Tests that validate_axioms.sh performs REAL validation, not just echoes.
# A valid ADE axiom validator must:
#   1. Check that required files exist (README.md, LICENSE)
#   2. Check that shell scripts have proper shebangs (#!/bin/bash)
#   3. Check that shell scripts are executable in git
#   4. Check that workflow YAML files are syntactically valid
#   5. Exit non-zero when any check fails
################################################################################

set -e

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=""

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/validate_axioms.sh"

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

echo "🧪 Running validate_axioms.sh Verification Tests..."
echo ""

##############################################################################
# TEST 1: Script must NOT be a no-op (must inspect files, not just echo)
##############################################################################
echo "--- Test: Script performs real file inspection ---"

# Count lines that actually DO something (not comments, not echo, not blank, not set)
real_lines=$(grep -cvE '^\s*$|^\s*#|^\s*echo |^\s*set |^\s*exit ' "$SCRIPT" 2>/dev/null || echo "0")

if [ "$real_lines" -gt 3 ]; then
  assert_pass "Script has $real_lines lines of real logic (beyond echo/comments)"
else
  assert_fail "Script has only $real_lines lines of real logic — likely a stub"
fi

##############################################################################
# TEST 2: Script must check for required files (README.md, LICENSE)
##############################################################################
echo ""
echo "--- Test: Script checks for required files ---"

if grep -qE 'README\.md|LICENSE' "$SCRIPT" 2>/dev/null; then
  assert_pass "Script references required files (README.md / LICENSE)"
else
  assert_fail "Script does not check for README.md or LICENSE"
fi

##############################################################################
# TEST 3: Script must validate shell script shebangs
##############################################################################
echo ""
echo "--- Test: Script validates shebangs ---"

if grep -qE 'shebang|#!/bin/bash|head -n' "$SCRIPT" 2>/dev/null; then
  assert_pass "Script contains shebang validation logic"
else
  assert_fail "Script does not validate shebangs"
fi

##############################################################################
# TEST 4: Script must have failure paths (exit 1 or non-zero exit)
##############################################################################
echo ""
echo "--- Test: Script can exit non-zero on failure ---"

if grep -qE 'exit 1|exit \$|FAILED=|failed=|ERRORS=|errors=' "$SCRIPT" 2>/dev/null; then
  assert_pass "Script has failure exit paths"
else
  assert_fail "Script always exits 0 — no failure detection"
fi

##############################################################################
# TEST 5: Script must pass when run against a valid repo
##############################################################################
echo ""
echo "--- Test: Script passes against current (valid) repo ---"

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
echo "✅ All validate_axioms.sh tests passed!"
exit 0
