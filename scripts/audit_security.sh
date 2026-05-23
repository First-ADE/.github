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
ERRORS=0

echo "🔍 Running Automated Security & Compliance Auditor..."

# 1. Check third-party Actions for commit SHA-pinning
echo "Checking GitHub Actions for commit SHA-pinning compliance..."
UNPINNED_ACTIONS=""
for wf in "$REPO_ROOT"/.github/workflows/*.yml "$REPO_ROOT"/.github/workflows/*.yaml; do
  [ -f "$wf" ] || continue
  wf_name=$(basename "$wf")
  while IFS= read -r line || [ -n "$line" ]; do
    if echo "$line" | grep -q 'uses:'; then
      action_ref=$(echo "$line" | sed 's/^[[:space:]]*uses:[[:space:]]*//' | tr -d '"'\' | tr -d '\r')
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
  if [ "$script_name" = "audit_security.sh" ]; then
    continue
  fi
  
  # Check for unvalidated eval
  if grep -n 'eval ' "$script" >/dev/null 2>&1; then
    SHELL_VULNS="$SHELL_VULNS\n  * $script_name contains 'eval' command"
  fi
  # Check for raw downloads executed directly (e.g. curl | sh)
  if grep -Pn 'curl[[:space:]]+.*\|[[:space:]]*(ba)?sh' "$script" >/dev/null 2>&1; then
    SHELL_VULNS="$SHELL_VULNS\n  * $script_name contains direct piped execution of curl downloads"
  fi
done

# Assemble findings context
FINDINGS_CONTEXT=""
if [ -n "$UNPINNED_ACTIONS" ]; then
  FINDINGS_CONTEXT="$FINDINGS_CONTEXT\n### Unpinned GitHub Actions Found:$UNPINNED_ACTIONS"
else
  FINDINGS_CONTEXT="$FINDINGS_CONTEXT\n### Unpinned GitHub Actions Found:\n  * None. All third-party actions are securely pinned to commit SHAs!"
fi

if [ -n "$SHELL_VULNS" ]; then
  FINDINGS_CONTEXT="$FINDINGS_CONTEXT\n\n### Script Hygiene Violations:$SHELL_VULNS"
else
  FINDINGS_CONTEXT="$FINDINGS_CONTEXT\n\n### Script Hygiene Violations:\n  * None. Shell scripts follow secure practices!"
fi

# 3. Call local Ollama model to formulate the report
PROMPT="You are an expert GitHub DevOps Security Auditor. Analyze the security audit findings below and formulate an automated markdown report.

---
## Security Findings
$FINDINGS_CONTEXT
---

Compile a highly professional report. It MUST strictly follow this exact format:

### 🚨 Automated Security & Compliance Auditor Report
*   **Compliance Status**: [Pass / Warn / Fail] (Fail if there are critical issues, Warn if there are unpinned actions or minor script warnings, Pass if clean)
*   **Vulnerabilities Found**: [Summarize findings or None]
*   **Actionable Recommendations**: [Provide concrete steps to pin actions to their commit SHAs and fix any script warnings]

Ensure all recommendations are actionable and direct. Do not write conversational preambles or postambles."

if curl -s -m 2 http://localhost:11434 >/dev/null; then
  echo "🤖 Submitting findings to local Ollama ($MODEL)..."
  REPORT=$(echo "$PROMPT" | ollama run "$MODEL" 2>/dev/null || echo "")
else
  echo "⚠️ Ollama server is unreachable. Using fallback offline security report generator."
  REPORT=""
fi

if [ -z "$REPORT" ]; then
  echo "❌ Failed to generate security report from local Ollama. Falling back..."
  # Fallback manual report if model is offline
  {
    echo "### 🚨 Automated Security & Compliance Auditor Report"
    if [ -n "$UNPINNED_ACTIONS" ] || [ -n "$SHELL_VULNS" ]; then
      echo "*   **Compliance Status**: [Warn]"
      echo "*   **Vulnerabilities Found**:"
      if [ -n "$UNPINNED_ACTIONS" ]; then
        echo "    - Unpinned third-party actions were identified."
      fi
      if [ -n "$SHELL_VULNS" ]; then
        echo "    - Dangerous shell script commands were detected."
      fi
      echo "*   **Actionable Recommendations**:"
      echo "    1. Pin third-party GitHub Actions to explicit commit SHAs."
      echo "    2. Review shell scripts to avoid direct curl execution or raw evaluations."
    else
      echo "*   **Compliance Status**: [Pass]"
      echo "*   **Vulnerabilities Found**: None"
      echo "*   **Actionable Recommendations**: All clean! Workflows are fully pinned and secure."
    fi
  } > SECURITY_AUDIT.md
else
  echo "✅ Security report compiled successfully!"
  echo "$REPORT" > SECURITY_AUDIT.md
fi

echo "--- Security Audit Preview ---"
cat SECURITY_AUDIT.md
echo "--- End of Preview ---"

# Set exit code based on report status
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
