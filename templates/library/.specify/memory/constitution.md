# {{project_name}} Constitution

*Project-specific governance derived from ADE Constitution v1.0.0*

---

## Project Mission

{{project_mission}}

---

## Governing Axioms

This project adheres to the [ADE Core Axioms](https://github.com/First-ADE/.github/docs/AXIOMS.md):

| Axiom                              | Application                                  |
| ---------------------------------- | -------------------------------------------- |
| **Σ.1** Specification Primacy      | All features have specs in `.specify/specs/` |
| **Σ.2** Deterministic Verification | pytest with >80% coverage                    |
| **Σ.3** Traceable Rationale        | ADRs in `docs/adr/`                          |
| **Σ.4** Emergent Complexity        | One module = one responsibility              |
| **Σ.5** AI Symbiosis               | Context files for agent guidance             |

---

## Project-Specific Postulates

*Derived from core postulates for this project's domain:*

| ID       | Postulate              | Derived From         |
| -------- | ---------------------- | -------------------- |
| Π.PROJ.1 | {{custom_postulate_1}} | {{parent_postulate}} |
| Π.PROJ.2 | {{custom_postulate_2}} | {{parent_postulate}} |

---

## Quality Gates

| Gate     | Tool          | Threshold |
| -------- | ------------- | --------- |
| Tests    | pytest        | 100% pass |
| Coverage | pytest-cov    | ≥80%      |
| Types    | mypy (strict) | 0 errors  |
| Lint     | ruff          | 0 errors  |

---

## AI Agent Guidance

When working on this project:

1. **Always read specifications first** — Check `.specify/specs/` before implementing
2. **Follow Red-Green-Refactor** — Failing test → Implementation → Cleanup
3. **Reference ADRs** — Check `docs/adr/` for architectural decisions
4. **Update this constitution** — If new constraints emerge, document them

---

**Version**: 1.0.0 | **Parent Constitution**: ADE v1.0.0
