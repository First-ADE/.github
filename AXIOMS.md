# First-ADE Axioms

This document defines the **formal axioms** for the `.github` organization repository.
Every axiom is a testable invariant that MUST hold at all times. Violations cause CI failure.

Axioms are enforced by `scripts/validate_axioms.sh` and verified by `tests/axioms_test.sh`.

---

## A1: Required Files

> Every repository MUST contain `README.md` and `LICENSE` at the root.

**Rationale:** A README ensures discoverability and onboarding. A LICENSE ensures legal clarity for contributors and consumers.

**Validation:** Check that both files exist at the repository root.

---

## A2: Shell Script Shebangs

> Every `.sh` file in `scripts/` MUST begin with a valid shebang (`#!/bin/bash` or `#!/bin/sh`).

**Rationale:** A missing or incorrect shebang causes silent failures across different execution environments (CI runners, containers, developer machines).

**Validation:** Read the first line of each `.sh` file and assert it matches `^#!/bin/(ba)?sh`.

---

## A3: Shell Script Permissions

> Every `.sh` file in `scripts/` MUST have the executable bit set in Git (`100755`).

**Rationale:** Without native executable permissions in the Git index, scripts require a `chmod +x` workaround at runtime — which is fragile, environment-dependent, and a security smell.

**Validation:** Query `git ls-files -s` for each script and assert mode is `100755`.

---

## A4: Workflow YAML Integrity

> Every `.yml` / `.yaml` file in `.github/workflows/` MUST be syntactically valid and contain a `jobs:` key.

**Rationale:** A malformed workflow file silently disables CI. Tab indentation (forbidden in YAML) and missing `jobs:` blocks are the most common structural errors.

**Validation:** Assert no tab indentation and assert the presence of a `jobs:` block.

## A5: CI Must Pass Before Merge

> All CI checks MUST pass before any pull request is merged to `main`.

**Rationale:** Merging with failing checks introduces broken invariants into the trunk. This axiom is the meta-guarantee that all other axioms are actually enforced. PR #19 was merged with a failing A3 check — this axiom exists to prevent that from ever recurring.

**Validation:** GitHub branch protection rules require status checks to pass. The `ade-verify.yml` workflow must be a required status check on `main`.

---

## Adding New Axioms

To add a new axiom:

1. Define it in this document with an `A<N>:` identifier, a `MUST` statement, rationale, and validation method.
2. Implement the check in `scripts/validate_axioms.sh`.
3. Add a test in `tests/axioms_test.sh` that verifies enforcement.
4. Run `./lib/bashunit tests/axioms_test.sh` to confirm.
