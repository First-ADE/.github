#!/bin/bash

################################################################################
# BDD Test Runner Script
#
# A lightweight, dependency-free BDD runner that parses Gherkin .feature files
# and executes step definitions defined in this script.
#
# Supported steps:
#   Given the repository root directory
#   Given the scripts in "<dir>" directory
#   Then the file "<name>" should exist
#   Then the directory "<name>" should exist
#   Then every ".sh" file should start with a shebang line
#   Then every ".sh" file should be executable in git
#
# Usage: ./scripts/run_bdd_tests.sh
################################################################################

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FEATURES_DIR="$REPO_ROOT/features"

SCENARIOS_RUN=0
SCENARIOS_PASSED=0
SCENARIOS_FAILED=0
STEPS_RUN=0
STEPS_PASSED=0
STEPS_FAILED=0
ERRORS=0
CONTEXT_DIR=""

pass_step() { STEPS_RUN=$((STEPS_RUN + 1)); STEPS_PASSED=$((STEPS_PASSED + 1)); echo "      ✅ $1"; }
fail_step() { STEPS_RUN=$((STEPS_RUN + 1)); STEPS_FAILED=$((STEPS_FAILED + 1)); ERRORS=$((ERRORS + 1)); echo "      ❌ $1"; }

##############################################################################
# Step Definitions
##############################################################################

step_given_repo_root() {
  CONTEXT_DIR="$REPO_ROOT"
  pass_step "Given the repository root directory"
}

step_given_scripts_dir() {
  local dir="$1"
  CONTEXT_DIR="$REPO_ROOT/$dir"
  if [ -d "$CONTEXT_DIR" ]; then
    pass_step "Given the scripts in \"$dir\" directory"
  else
    fail_step "Given the scripts in \"$dir\" directory — directory not found"
  fi
}

step_then_file_exists() {
  local filename="$1"
  if [ -f "$CONTEXT_DIR/$filename" ]; then
    pass_step "Then the file \"$filename\" should exist"
  else
    fail_step "Then the file \"$filename\" should exist — NOT FOUND"
  fi
}

step_then_dir_exists() {
  local dirname="$1"
  if [ -d "$CONTEXT_DIR/$dirname" ]; then
    pass_step "Then the directory \"$dirname\" should exist"
  else
    fail_step "Then the directory \"$dirname\" should exist — NOT FOUND"
  fi
}

step_then_shebang() {
  local failed=0
  for script in "$CONTEXT_DIR"/*.sh; do
    [ -f "$script" ] || continue
    first_line=$(head -n 1 "$script" | tr -d '\r')
    if ! echo "$first_line" | grep -qE '^#!/bin/(ba)?sh'; then
      fail_step "Then $(basename "$script") should start with a shebang — got '$first_line'"
      failed=1
    fi
  done
  if [ "$failed" -eq 0 ]; then
    pass_step "Then every \".sh\" file should start with a shebang line"
  fi
}

step_then_executable() {
  local failed=0
  for script in "$CONTEXT_DIR"/*.sh; do
    [ -f "$script" ] || continue
    name="$(basename "$script")"
    rel="scripts/$name"
    mode=$(git -C "$REPO_ROOT" ls-files -s "$rel" 2>/dev/null | awk '{print $1}')
    if [ "$mode" != "100755" ]; then
      fail_step "Then $name should be executable — mode is ${mode:-unknown}"
      failed=1
    fi
  done
  if [ "$failed" -eq 0 ]; then
    pass_step "Then every \".sh\" file should be executable in git"
  fi
}

step_then_sh_has_ps1() {
  local failed=0
  for script in "$CONTEXT_DIR"/*.sh; do
    [ -f "$script" ] || continue
    local base="${script%.sh}"
    local ps1_script="${base}.ps1"
    if [ ! -f "$ps1_script" ]; then
      fail_step "Then $(basename "$script") should have a corresponding .ps1 script — NOT FOUND"
      failed=1
    fi
  done
  if [ "$failed" -eq 0 ]; then
    pass_step "Then every \".sh\" file should have a corresponding \".ps1\" script"
  fi
}

step_then_ps1_has_sh() {
  local failed=0
  for script in "$CONTEXT_DIR"/*.ps1; do
    [ -f "$script" ] || continue
    local base="${script%.ps1}"
    local sh_script="${base}.sh"
    if [ ! -f "$sh_script" ]; then
      fail_step "Then $(basename "$script") should have a corresponding .sh script — NOT FOUND"
      failed=1
    fi
  done
  if [ "$failed" -eq 0 ]; then
    pass_step "Then every \".ps1\" file should have a corresponding \".sh\" script"
  fi
}


##############################################################################
# Gherkin Parser & Runner
##############################################################################

run_feature_file() {
  local feature_file="$1"
  local feature_name=""
  local in_scenario=0
  local scenario_name=""
  local scenario_failed=0

  echo ""
  echo "📄 Feature file: $(basename "$feature_file")"

  while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    line="$(echo "$raw_line" | sed 's/\r$//' | sed 's/^[[:space:]]*//')"

    # Skip blank lines and comments
    [ -z "$line" ] && continue

    case "$line" in
      Feature:*)
        feature_name="${line#Feature: }"
        echo "  📋 Feature: $feature_name"
        ;;
      Scenario:*)
        # Close previous scenario
        if [ "$in_scenario" -eq 1 ]; then
          SCENARIOS_RUN=$((SCENARIOS_RUN + 1))
          if [ "$scenario_failed" -eq 0 ]; then
            SCENARIOS_PASSED=$((SCENARIOS_PASSED + 1))
          else
            SCENARIOS_FAILED=$((SCENARIOS_FAILED + 1))
          fi
        fi
        scenario_name="${line#Scenario: }"
        echo ""
        echo "    🎬 Scenario: $scenario_name"
        in_scenario=1
        scenario_failed=0
        ;;
      "Given the repository root directory")
        step_given_repo_root
        ;;
      Given\ the\ scripts\ in\ \"*\"\ directory)
        dir=$(echo "$line" | sed 's/Given the scripts in "\(.*\)" directory/\1/')
        step_given_scripts_dir "$dir"
        ;;
      Then\ the\ file\ \"*\"\ should\ exist)
        file=$(echo "$line" | sed 's/Then the file "\(.*\)" should exist/\1/')
        old_errors=$ERRORS
        step_then_file_exists "$file"
        [ "$ERRORS" -gt "$old_errors" ] && scenario_failed=1
        ;;
      Then\ the\ directory\ \"*\"\ should\ exist)
        dir=$(echo "$line" | sed 's/Then the directory "\(.*\)" should exist/\1/')
        old_errors=$ERRORS
        step_then_dir_exists "$dir"
        [ "$ERRORS" -gt "$old_errors" ] && scenario_failed=1
        ;;
      "Then every \".sh\" file should start with a shebang line")
        old_errors=$ERRORS
        step_then_shebang
        [ "$ERRORS" -gt "$old_errors" ] && scenario_failed=1
        ;;
      "Then every \".sh\" file should be executable in git")
        old_errors=$ERRORS
        step_then_executable
        [ "$ERRORS" -gt "$old_errors" ] && scenario_failed=1
        ;;
      "Then every \".sh\" file should have a corresponding \".ps1\" script")
        old_errors=$ERRORS
        step_then_sh_has_ps1
        [ "$ERRORS" -gt "$old_errors" ] && scenario_failed=1
        ;;
      "Then every \".ps1\" file should have a corresponding \".sh\" script")
        old_errors=$ERRORS
        step_then_ps1_has_sh
        [ "$ERRORS" -gt "$old_errors" ] && scenario_failed=1
        ;;
      As\ *|I\ want\ *|So\ that\ *)
        # Narrative lines — skip silently
        ;;
      *)
        echo "      ⚠️  Undefined step: $line"
        ;;
    esac
  done < "$feature_file"

  # Close last scenario
  if [ "$in_scenario" -eq 1 ]; then
    SCENARIOS_RUN=$((SCENARIOS_RUN + 1))
    if [ "$scenario_failed" -eq 0 ]; then
      SCENARIOS_PASSED=$((SCENARIOS_PASSED + 1))
    else
      SCENARIOS_FAILED=$((SCENARIOS_FAILED + 1))
    fi
  fi
}

##############################################################################
# Main
##############################################################################

echo "🧪 Starting BDD Test Execution..."

if [ ! -d "$FEATURES_DIR" ]; then
  echo "❌ No features/ directory found at $FEATURES_DIR"
  exit 1
fi

feature_files=$(find "$FEATURES_DIR" -name "*.feature" | sort)

if [ -z "$feature_files" ]; then
  echo "❌ No .feature files found in $FEATURES_DIR"
  exit 1
fi

for f in $feature_files; do
  run_feature_file "$f"
done

echo ""
echo "======================================"
echo "  Scenarios: $SCENARIOS_RUN ($SCENARIOS_PASSED passed, $SCENARIOS_FAILED failed)"
echo "  Steps:     $STEPS_RUN ($STEPS_PASSED passed, $STEPS_FAILED failed)"
echo "======================================"

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "❌ $ERRORS BDD test failure(s)!"
  exit 1
fi

echo ""
echo "✅ All BDD tests passed!"
exit 0
