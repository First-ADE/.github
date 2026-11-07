#!/bin/bash
# bashunit tests for axioms A8 and A9 (independence, license holder, honest README).

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/validate_axioms.sh"

make_fixture() {
  local dir
  dir="$(mktemp -d)"
  git -C "$dir" init -q
  mkdir -p "$dir/scripts"
  cp "$REPO_ROOT/LICENSE" "$dir/LICENSE"
  printf '# fixture\n\n> **Status:** test fixture.\n\n## Independence\n\nPersonal project.\n' > "$dir/README.md"
  git -C "$dir" add -A
  git -C "$dir" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm init
  echo "$dir"
}

function test_a8_a9_pass_on_compliant_fixture() {
  local dir
  dir="$(make_fixture)"
  assert_exit_code 0 "$(ADE_REPO_ROOT="$dir" "$VALIDATOR" > /dev/null 2>&1)"
}

function test_a8_fails_when_holder_is_not_a_person() {
  local dir
  dir="$(make_fixture)"
  sed -i 's/Brandon Fox/ALOS Engineering Team/' "$dir/LICENSE"
  output="$(ADE_REPO_ROOT="$dir" "$VALIDATOR" 2>&1 || true)"
  assert_contains "FAIL: LICENSE must be MIT" "$output"
}

function test_a8_fails_without_independence_section() {
  local dir
  dir="$(make_fixture)"
  printf '# fixture\n\n> **Status:** test fixture.\n' > "$dir/README.md"
  output="$(ADE_REPO_ROOT="$dir" "$VALIDATOR" 2>&1 || true)"
  assert_contains "missing a '## Independence' section" "$output"
}

function test_a9_fails_without_status_line() {
  local dir
  dir="$(make_fixture)"
  printf '# fixture\n\nNo status here.\n\n## Independence\n\nPersonal.\n' > "$dir/README.md"
  output="$(ADE_REPO_ROOT="$dir" "$VALIDATOR" 2>&1 || true)"
  assert_contains "must contain a line starting '> **Status:**'" "$output"
}

function test_axioms_doc_and_script_agree() {
  local doc_ids script_ids
  doc_ids="$(grep -oE '^## A[0-9]+:' "$REPO_ROOT/AXIOMS.md" | grep -oE 'A[0-9]+' | sort -u | tr '\n' ' ')"
  script_ids="$(grep -oE '^# AXIOM [0-9]+' "$VALIDATOR" | grep -oE '[0-9]+' | sed 's/^/A/' | sort -u | tr '\n' ' ')"
  assert_equals "$doc_ids" "$script_ids"
}
