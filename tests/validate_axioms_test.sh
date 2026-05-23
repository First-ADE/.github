#!/bin/bash

# Test: validate_axioms.sh Verification
# Verifies the axiom validation script performs real checks

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/validate_axioms.sh"

function test_script_has_real_logic_beyond_echo_stubs() {
  local real_lines
  real_lines=$(grep -cvE '^\s*$|^\s*#|^\s*echo |^\s*set |^\s*exit ' "$SCRIPT" 2>/dev/null)
  assert_greater_than 3 "$real_lines"
}

function test_script_checks_for_readme() {
  assert_contains "README.md" "$(cat "$SCRIPT")"
}

function test_script_checks_for_license() {
  assert_contains "LICENSE" "$(cat "$SCRIPT")"
}

function test_script_validates_shebangs() {
  assert_contains "shebang" "$(cat "$SCRIPT")"
}

function test_script_has_failure_exit_path() {
  assert_contains "exit 1" "$(cat "$SCRIPT")"
}

function test_script_tracks_error_count() {
  assert_contains "ERRORS=" "$(cat "$SCRIPT")"
}

function test_script_passes_on_valid_repo() {
  assert_exit_code 0 "$SCRIPT"
}
