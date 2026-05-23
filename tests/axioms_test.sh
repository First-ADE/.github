#!/bin/bash

# Test: Axiom Specification
# Verifies that axioms are formally defined and enforceable

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

function test_axioms_md_exists() {
  assert_file_exists "$REPO_ROOT/AXIOMS.md"
}

function test_axioms_md_defines_axiom_ids() {
  local content
  content=$(cat "$REPO_ROOT/AXIOMS.md")
  assert_contains "A1:" "$content"
  assert_contains "A2:" "$content"
  assert_contains "A3:" "$content"
  assert_contains "A4:" "$content"
}

function test_axioms_md_has_testable_statements() {
  local content
  content=$(cat "$REPO_ROOT/AXIOMS.md")
  assert_contains "MUST" "$content"
}

function test_every_axiom_has_a_validation_check() {
  # Each axiom ID in AXIOMS.md should appear in validate_axioms.sh
  local axiom_ids
  axiom_ids=$(grep -oE 'A[0-9]+:' "$REPO_ROOT/AXIOMS.md" 2>/dev/null | sort -u)
  local script
  script=$(cat "$REPO_ROOT/scripts/validate_axioms.sh")
  for id in $axiom_ids; do
    assert_contains "$id" "$script"
  done
}

function test_validate_axioms_passes() {
  assert_exit_code 0 "$REPO_ROOT/scripts/validate_axioms.sh"
}
