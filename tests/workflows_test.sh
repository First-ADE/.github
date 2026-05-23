#!/bin/bash

# Test: Workflow Validation
# Verifies GitHub Actions workflows are well-formed

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW_DIR="$REPO_ROOT/.github/workflows"

function test_ade_verify_yml_does_not_self_reference() {
  local result
  result=$(grep "uses:.*workflows/ade-verify.yml@" "$WORKFLOW_DIR/ade-verify.yml" 2>/dev/null || true)
  assert_empty "$result"
}

function test_verify_yml_does_not_self_reference() {
  local result
  result=$(grep "uses:.*workflows/verify.yml@" "$WORKFLOW_DIR/verify.yml" 2>/dev/null || true)
  assert_empty "$result"
}

function test_ade_verify_yml_has_trigger() {
  local content
  content=$(cat "$WORKFLOW_DIR/ade-verify.yml")
  assert_contains "on:" "$content"
}

function test_verify_yml_has_trigger() {
  local content
  content=$(cat "$WORKFLOW_DIR/verify.yml")
  assert_contains "on:" "$content"
}

function test_ade_verify_yml_references_resolve() {
  # Extract workflow file references from uses: lines
  local refs
  refs=$(grep -o 'workflows/[^@]*' "$WORKFLOW_DIR/ade-verify.yml" 2>/dev/null | sed 's|workflows/||' || true)
  if [ -n "$refs" ]; then
    for ref in $refs; do
      assert_file_exists "$WORKFLOW_DIR/$ref"
    done
  else
    # No refs to check — that's fine
    assert_empty "$refs"
  fi
}

function test_verify_yml_references_resolve() {
  local refs
  refs=$(grep -o 'workflows/[^@]*' "$WORKFLOW_DIR/verify.yml" 2>/dev/null | sed 's|workflows/||' || true)
  if [ -n "$refs" ]; then
    for ref in $refs; do
      assert_file_exists "$WORKFLOW_DIR/$ref"
    done
  else
    assert_empty "$refs"
  fi
}
