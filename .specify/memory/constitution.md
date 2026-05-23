<!--
SYNC IMPACT REPORT
Version change: None -> 1.0.0
Modified principles:
- I. Required Files (A1) (Added)
- II. Shell Script Shebangs (A2) (Added)
- III. Shell Script Permissions (A3) (Added)
- IV. Workflow YAML Integrity (A4) (Added)
- V. CI Must Pass Before Merge (A5) (Added)
Added sections:
- Additional Constraints
- Development Workflow
Removed sections: None
Templates requiring updates:
- .specify/templates/plan-template.md (✅ updated)
- .specify/templates/spec-template.md (✅ updated)
- .specify/templates/tasks-template.md (✅ updated)
Follow-up TODOs: None
-->

# First-ADE/.github Constitution

## Core Principles

### I. Required Files (A1)
Every repository within the First-ADE organization MUST contain `README.md`, `LICENSE`, and `AXIOMS.md` at the root.

**Rationale:** A README ensures discoverability and onboarding for contributors. A LICENSE provides clear legal usage terms. An AXIOMS.md establishes the core rules of the repository from day one.

### II. Shell Script Shebangs (A2)
Every `.sh` file in the `scripts/` directory MUST begin with a valid shebang (`#!/bin/bash` or `#!/bin/sh`).

**Rationale:** Missing or malformed shebangs cause silent failures across different OS/CI runtimes (e.g. standard developer workstations vs. Ubuntu runners in GitHub Actions).

### III. Shell Script Permissions (A3)
Every `.sh` file in the `scripts/` directory MUST have the executable bit set in Git (`100755`).

**Rationale:** Without native executable permissions tracked in the Git index, execution requires brittle `chmod` overrides at runtime which is environment-dependent and hard to enforce in CI.

### IV. Workflow YAML Integrity (A4)
Every `.yml` / `.yaml` file in the `.github/workflows/` directory MUST be syntactically valid YAML, contain a `jobs:` key, and use spaces instead of tabs for indentation.

**Rationale:** Syntactically malformed workflows or tabs in YAML will cause GitHub to silently skip or fail the CI trigger, leading to unverified commits.

### V. CI Must Pass Before Merge (A5)
All CI status checks MUST pass successfully before any pull request is merged to the `main` branch. The `ade-verify.yml` workflow must be configured as a required status check on `main`.

**Rationale:** This axiom acts as the meta-guarantee that all other axioms are actually enforced, preventing broken invariants from being merged to the trunk.

## Additional Constraints

All repository validation scripts and tests must reside within the standard `scripts/` and `tests/` directories respectively, ensuring clean structure across organizational projects.

## Development Workflow

To add a new axiom to the repository:
1. Define the axiom formally in `AXIOMS.md` with an `A<N>:` identifier, a `MUST` statement, a detailed rationale, and validation method.
2. Implement the validation logic within `scripts/validate_axioms.sh`.
3. Add a corresponding test block in `tests/axioms_test.sh` that asserts correct enforcement.
4. Run `./lib/bashunit tests/axioms_test.sh` (or using configured runners) to confirm validation.

## Governance

This constitution is the supreme definition of project health and structure. All pull requests, reviews, and automated checks must verify compliance with these core principles. Any modifications to these principles require formal updates through the 'Development Workflow' process, incrementing the constitution version.

**Version**: 1.0.0 | **Ratified**: 2026-05-23 | **Last Amended**: 2026-05-23
