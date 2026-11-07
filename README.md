# First-ADE/.github

> **Status:** active, single maintainer. The organization-level repository for First-ADE: axioms, validator, reusable CI action, principles, and the org profile page.

Axiom-Driven Engineering (ADE) writes down the properties a system must never violate as falsifiable axioms, gives every axiom a check, and runs the check on every commit. This repository is the smallest working example of that: nine axioms about repository structure and conduct in [`AXIOMS.md`](AXIOMS.md), enforced by [`scripts/validate_axioms.sh`](scripts/validate_axioms.sh), specified in [`features/`](features/), tested in [`tests/`](tests/).

## What is here

| Path | Purpose |
| --- | --- |
| [`AXIOMS.md`](AXIOMS.md) | The nine axioms, each with rationale and validation method. |
| [`PRINCIPLES.md`](PRINCIPLES.md) | The six standing rules every repository under brandon-fox, First-ADE and vindicta-platform is held to. |
| [`scripts/validate_axioms.sh`](scripts/validate_axioms.sh) | The validator. Run it in any clone; point it elsewhere with `ADE_REPO_ROOT`. |
| [`scripts/run_bdd_tests.sh`](scripts/run_bdd_tests.sh) | A dependency-free Gherkin runner for the feature files. |
| [`.github/actions/ade-axioms`](.github/actions/ade-axioms) | Composite action that runs the validator against the calling repository. |
| [`profile/README.md`](profile/README.md) | The organization profile page. |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to contribute, including DCO sign-off. |

## Use the checks in your repository

```yaml
# .github/workflows/ade.yml
name: ADE axioms
on: [push, pull_request]
jobs:
  axioms:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: First-ADE/.github/.github/actions/ade-axioms@main
```

The action checks A1–A4 and A6–A9 against your repository. A5 is a branch-protection setting, not a runtime check.

## Run locally

```bash
./scripts/validate_axioms.sh          # the axioms
./scripts/run_bdd_tests.sh            # the feature files
curl -s https://bashunit.typeddevs.com/install.sh | bash && ./lib/bashunit tests/
```

## Independence

This is a personal project by Brandon Fox, built on my own time and equipment. It is not affiliated with, endorsed by, or derived from the work of any employer, current or former, and does not represent their views, products or practices. Licensed under the MIT License; principles at [PRINCIPLES.md](PRINCIPLES.md).
