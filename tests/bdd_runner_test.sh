#!/bin/bash

# Test: run_bdd_tests.sh Verification
# Verifies the BDD runner executes real feature specs

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/run_bdd_tests.sh"

function test_script_has_real_logic() {
  local real_lines
  real_lines=$(grep -cvE '^\s*$|^\s*#|^\s*echo |^\s*set |^\s*exit ' "$SCRIPT" 2>/dev/null)
  assert_greater_than 3 "$real_lines"
}

function test_script_references_feature_files() {
  assert_contains ".feature" "$(cat "$SCRIPT")"
}

function test_script_has_failure_exit_path() {
  assert_contains "exit 1" "$(cat "$SCRIPT")"
}

function test_feature_files_exist() {
  local count
  count=$(find "$REPO_ROOT/features" -name "*.feature" 2>/dev/null | wc -l | tr -d ' ')
  assert_greater_than 0 "$count"
}

function test_script_passes_on_valid_repo() {
  assert_exit_code 0 "$SCRIPT"
}
