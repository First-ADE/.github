# First-ADE

> **Status:** active, single maintainer, pre-1.0. A personal initiative by [Brandon Fox](https://github.com/brandon-fox), not a company or a team.

I build systems where the spec is the truth, the invariants are enforced by CI, and all of it is public. **Axiom-Driven Engineering (ADE)** is the name for that practice applied to AI-native software: the properties a system must never violate are written down as axioms, every axiom has a check, and the check runs on every commit. A model may be non-deterministic; the envelope around it is not.

## The three pillars

| Pillar | What it means | Where it lives |
| --- | --- | --- |
| **System invariants** | Repository and build properties stated as falsifiable axioms (`A1`…`A9`) and validated by script on every push and pull request. | [`AXIOMS.md`](https://github.com/First-ADE/.github/blob/main/AXIOMS.md), [`scripts/validate_axioms.sh`](https://github.com/First-ADE/.github/blob/main/scripts/validate_axioms.sh) |
| **Agentic determinism** | Runtime envelopes around model calls: prompt contracts validated as code, structured outputs validated against schemas before anything executes. | [`first-ade`](https://github.com/First-ADE/first-ade) compliance engines (spec, test, traceability, ADR, forbidden-API) |
| **Granular governance** | Prompts and model configuration are code: reviewed, versioned, traceable to a specification and an architecture decision record. | [`first-ade`](https://github.com/First-ADE/first-ade) `docs/adr/`, `docs/POSTULATES.md`, `docs/CONSTITUTION.md` |

## Repositories

| Repository | What it is | Status (by last push) | Stack |
| --- | --- | --- | --- |
| [`first-ade`](https://github.com/First-ADE/first-ade) | The ADE Compliance Framework: a CLI and FastAPI gateway that runs verification engines over a codebase and keeps a hash-chained audit log. | Active, 0.1.0, last push June 2026 | Python 3.11, Pydantic v2, SQLAlchemy, pyadr |
| [`.github`](https://github.com/First-ADE/.github) | This repository: the axioms, the validator, the reusable CI action, the principles. | Active | Bash, bashunit, GitHub Actions |
| `Constitution-MCP` | A Model Context Protocol server that serves agent constitutions and policies. | Private; last push February 2026 | Python |

Applications of the method outside this org: [`alos`](https://github.com/brandon-fox/alos), a local-first autonomous agent runtime built spec-first, and the [Vindicta Platform](https://github.com/vindicta-platform) design record.

## Start here

1. Read [`AXIOMS.md`](https://github.com/First-ADE/.github/blob/main/AXIOMS.md): nine invariants, each with a rationale and the exact check.
2. Run `./scripts/validate_axioms.sh` in any clone; it fails loudly on the first violation.
3. Read [`PRINCIPLES.md`](https://github.com/First-ADE/.github/blob/main/PRINCIPLES.md) for the rules every repository here is held to.
4. To use the checks in your own repository, add the `First-ADE/.github/.github/actions/ade-axioms` action to a workflow.

## Contributing

Pull requests are welcome. Sign each commit with the Developer Certificate of Origin (`git commit -s`); see [`CONTRIBUTING.md`](https://github.com/First-ADE/.github/blob/main/CONTRIBUTING.md). Code of conduct: [`CODE_OF_CONDUCT.md`](https://github.com/First-ADE/.github/blob/main/.github/CODE_OF_CONDUCT.md).

Contact: bfoxtrotfarm@gmail.com · [LinkedIn](https://www.linkedin.com/in/brandonlouisfox)

---

All work here is personal and independent of any employer. Views, writing and code are my own. MIT licensed, copyright Brandon Fox.
