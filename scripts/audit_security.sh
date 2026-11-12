#!/bin/bash
################################################################################
# audit_security.sh
#
# Automated Security & Compliance Auditor. Audits GitHub Actions SHA-pinning,
# checks shell script hygiene, and feeds findings into local Ollama.
#
# Usage: ./scripts/audit_security.sh
################################################################################

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODEL="${AUDIT_MODEL:-qwen2.5-coder:3b}"

echo "🔍 Running Automated Security & Compliance Auditor..."

# 1. Check third-party Actions for commit SHA-pinning
echo "Checking GitHub Actions for commit SHA-pinning compliance..."
UNPINNED_ACTIONS=""
for wf in "$REPO_ROOT"/.github/workflows/*.yml "$REPO_ROOT"/.github/workflows/*.yaml; do
  [ -f "$wf" ] || continue
  wf_name=$(basename "$wf")
  while IFS= read -r line || [ -n "$line" ]; do
    if echo "$line" | grep -qE '^[[:space:]]*(-[[:space:]]*)?uses:'; then
      action_ref=$(echo "$line" | sed -E 's/^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*//; s/[[:space:]]*#.*$//' | tr -d '"' | tr -d "'" | tr -d '\r')
      # Skip local actions (starting with ./ or .)
      if [[ "$action_ref" =~ ^\./ ]] || [[ "$action_ref" =~ ^\. ]] || [[ -z "$action_ref" ]]; then
        continue
      fi
      # Check if reference is pinned to a 40-character commit SHA
      if ! echo "$action_ref" | grep -qE '@[0-9a-fA-F]{40}$'; then
        UNPINNED_ACTIONS="$UNPINNED_ACTIONS\n  * In $wf_name: '$action_ref'"
      fi
    fi
  done < "$wf"
done

# 2. Check shell scripts for vulnerable patterns (e.g. unvalidated eval, shell execution privileges)
echo "Auditing shell scripts for secure execution patterns..."
SHELL_VULNS=""
for script in "$REPO_ROOT"/scripts/*.sh; do
  [ -f "$script" ] || continue
  script_name=$(basename "$script")
  [ "$script_name" = "audit_security.sh" ] && continue

  # Check for unvalidated eval
  if grep -nE '(^|[[:space:];])eval[[:space:]]' "$script" >/dev/null 2>&1; then
    SHELL_VULNS="$SHELL_VULNS\n  * $script_name contains 'eval' command"
  fi
  # Check for raw downloads executed directly (e.g. curl | sh)
  if grep -Pn 'curl[[:space:]]+.*\|[[:space:]]*(ba)?sh' "$script" >/dev/null 2>&1; then
    SHELL_VULNS="$SHELL_VULNS\n  * $script_name contains direct piped execution of curl downloads"
  fi
done

if [ -z "$UNPINNED_ACTIONS" ] && [ -z "$SHELL_VULNS" ]; then
  {
    echo "### 🚨 Automated Security & Compliance Auditor Report"
    echo "*   **Compliance Status**: [Pass]"
    echo "*   **Vulnerabilities Found**: None. All third-party actions are pinned to 40-character commit SHAs and shell scripts follow secure practices."
    echo "*   **Actionable Recommendations**: None required."
  } > SECURITY_AUDIT.md
else
  {
    echo "### 🚨 Automated Security & Compliance Auditor Report"
    echo "*   **Compliance Status**: [Warn]"
    echo "*   **Vulnerabilities Found**:"
    if [ -n "$UNPINNED_ACTIONS" ]; then
      echo -e "    - Unpinned third-party actions:$UNPINNED_ACTIONS"
    fi
    if [ -n "$SHELL_VULNS" ]; then
      echo -e "    - Shell script warnings:$SHELL_VULNS"
    fi
    echo "*   **Actionable Recommendations**:"
    echo "    1. Pin third-party GitHub Actions to explicit commit SHAs."
    echo "    2. Review shell scripts to avoid direct curl execution or raw evaluations."
  } > SECURITY_AUDIT.md
fi

echo "--- Security Audit Preview ---"
cat SECURITY_AUDIT.md
echo "--- End of Preview ---"

if grep -q "Compliance Status: \[Fail\]" SECURITY_AUDIT.md; then
  echo "❌ Security Audit Failed!"
  exit 1
elif grep -q "Compliance Status: \[Warn\]" SECURITY_AUDIT.md; then
  echo "⚠️ Security Audit completed with warnings."
  exit 0
else
  echo "✅ Security Audit passed cleanly!"
  exit 0
fi