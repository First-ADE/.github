# First-ADE Axioms

This document defines the **formal axioms** for repositories governed by First-ADE.
Every axiom is a testable invariant that MUST hold at all times. Violations cause CI failure.

Axioms are enforced by `scripts/validate_axioms.sh` and verified by `tests/axioms_test.sh`. The script checks the repository it runs in; the reusable action in `.github/actions/ade-axioms` runs the same script against any repository that calls it. Every axiom listed here has a corresponding block in the script, and every block in the script has an entry here; a mismatch between the two is itself a violation.

---

## A1: Required Files

> Every repository MUST contain `README.md` and `LICENSE` at the root. This repository MUST also contain `AXIOMS.md`.

**Rationale:** A README ensures discoverability and onboarding. A LICENSE ensures legal clarity for contributors and consumers.

**Validation:** Check that the files exist at the repository root.

---

## A2: Shell Script Shebangs

> Every `.sh` file in `scripts/` MUST begin with a valid shebang (`#!/bin/bash` or `#!/bin/sh`).

**Rationale:** A missing or incorrect shebang causes silent failures across different execution environments (CI runners, containers, developer machines).

**Validation:** Read the first line of each `.sh` file and assert it matches `^#!/bin/(ba)?sh`.

---

## A3: Shell Script Permissions

> Every `.sh` file in `scripts/` MUST have the executable bit set in Git (`100755`).

**Rationale:** Without native executable permissions in the Git index, scripts require a `chmod +x` workaround at runtime, which is fragile, environment-dependent, and a security smell.

**Validation:** Query `git ls-files -s` for each script and assert mode is `100755`.

---

## A4: Workflow YAML Integrity

> Every `.yml` / `.yaml` file in `.github/workflows/` MUST be syntactically valid and contain a `jobs:` key.

**Rationale:** A malformed workflow file silently disables CI. Tab indentation (forbidden in YAML) and missing `jobs:` blocks are the most common structural errors.

**Validation:** Assert no tab indentation and assert the presence of a `jobs:` block.

---

## A5: CI Must Pass Before Merge

> All CI checks MUST pass before any pull request is merged to `main`.

**Rationale:** Merging with failing checks introduces broken invariants into the trunk. This axiom is the meta-guarantee that all other axioms are actually enforced. PR #19 was merged with a failing A3 check; this axiom exists to prevent that from ever recurring.

**Validation:** GitHub branch protection rules require status checks to pass. The `ade-verify.yml` workflow must be a required status check on `main`.

---

## A6: No Unresolved Conflict Markers

> No tracked file MUST contain an unresolved Git conflict marker (`<<<<<<<` or `>>>>>>>` at the start of a line).

**Rationale:** A merged conflict marker is a broken file that may still parse, compile or render, and so escapes notice until it fails somewhere else.

**Validation:** Recursive grep for lines beginning with `<<<<<<<` or `>>>>>>>`, excluding `.git`, vendored directories and the validator itself.

---

## A7: Commits Are Signed

> Every commit on a branch under review MUST carry a cryptographic signature (GPG or SSH).

**Rationale:** Attribution is a principle (PRINCIPLES.md §4). A signed commit ties authorship to a key the author controls, so attribution cannot be forged by setting a name in `git config`.

**Validation:** For every commit in `origin/main...HEAD`, the commit object must carry a `gpgsig` header (`git cat-file commit <sha>`). Verification of the signature against a key is done by GitHub on push, not by the runner.

---

## A8: Independence and License Holder

> `LICENSE` MUST be the MIT License with the copyright line `Copyright (c) <year> Brandon Fox`, and `README.md` MUST contain a section headed `## Independence` stating that the work is personal and represents no employer.

**Rationale:** Principles 1 and 5 (open by default; mine alone). A full MIT grant with a named human holder makes the terms of use unambiguous, and the Independence section makes the separation from any employer explicit on the surface a reader actually opens.

**Validation:** `LICENSE` contains `MIT License` and a line matching `^Copyright \(c\) [0-9]{4} Brandon Fox$`; `README.md` contains a line matching `^## Independence`.

---

## A9: README States What and Status

> The first line of `README.md` MUST be a level-one heading naming the project, and one of the next ten lines MUST begin with `> **Status:**` stating the project's real status.

**Rationale:** Principle 3 (honest code). A reader learns what the thing is and whether it is active, a design study, pre-release or archived before reading anything else; the status line is the one that is hardest to leave stale by accident because the check looks for it.

**Validation:** Line 1 matches `^# `; a line among lines 2–11 matches `^> \*\*Status:\*\*`.

---

## Adding New Axioms

To add a new axiom:

1. Define it in this document with an `A<N>:` identifier, a `MUST` statement, rationale, and validation method.
2. Implement the check in `scripts/validate_axioms.sh` under a header that names the same `A<N>`.
3. Add a scenario to `features/` and a test in `tests/axioms_test.sh` that verifies enforcement.
4. Run `./lib/bashunit tests/axioms_test.sh` to confirm.
