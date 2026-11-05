# Contributing

Thank you for considering a contribution. This organization is a personal initiative maintained by one person, so expect honest but not instant review.

## Ground rules

1. Read [`AXIOMS.md`](AXIOMS.md). Every pull request must pass `./scripts/validate_axioms.sh`; CI runs it and `main` requires it.
2. Read [`PRINCIPLES.md`](PRINCIPLES.md). Changes that would make a README less honest about status, or weaken the license grant, will not be merged.
3. Specs before code. A behavioural change arrives with its feature file under `features/` (or its `spec.md` under `specs/`) in the same pull request.

## Developer Certificate of Origin

Every commit must be signed off, which certifies that you wrote the change or have the right to submit it under the MIT License, per the [Developer Certificate of Origin 1.1](https://developercertificate.org/):

```bash
git commit -s -m "feat(scope): what changed"
```

This adds a `Signed-off-by: Your Name <you@example.com>` trailer. Your contribution is attributed to you, in your name, in the git history; copyright in your contribution stays with you, licensed to the project under MIT.

Commits must also carry a cryptographic signature (axiom A7). GitHub's guide to [signing commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits) covers SSH and GPG.

## Workflow

1. Fork, branch from `main` with a short name such as `feat/axiom-a10` or `fix/runner-crlf`.
2. Make the change; run `./scripts/validate_axioms.sh`, `./scripts/run_bdd_tests.sh` and `./lib/bashunit tests/` locally.
3. Open a pull request using the template. One change per pull request.
4. Expect review within a week. Review is of the change, never of the person.

## Code of conduct

[`.github/CODE_OF_CONDUCT.md`](.github/CODE_OF_CONDUCT.md). Report concerns to bfoxtrotfarm@gmail.com.
