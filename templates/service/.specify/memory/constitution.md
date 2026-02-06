# {{service_name}} Constitution

*Service-specific governance derived from ADE Constitution v1.0.0*

---

## Service Mission

{{service_mission}}

---

## Governing Axioms

| Axiom   | Application                                          |
| ------- | ---------------------------------------------------- |
| **Σ.1** | API specs in `.specify/specs/` before implementation |
| **Σ.2** | Unit + Integration tests with >80% coverage          |
| **Σ.3** | ADRs for all architectural decisions                 |
| **Σ.4** | Route → Service → Model layered architecture         |
| **Σ.5** | Context files for agent guidance                     |

---

## Architectural Constraints

### Layer Responsibilities

```
routes/     — HTTP handling only, no business logic
services/   — Business logic, orchestration
models/     — Data structures, validation
utils/      — Pure utility functions
```

### Dependency Direction

```
routes → services → models
            ↓
         utils (shared)
```

---

## Quality Gates

| Gate              | Tool           | Threshold |
| ----------------- | -------------- | --------- |
| Unit Tests        | pytest         | 100% pass |
| Integration Tests | pytest + httpx | 100% pass |
| Coverage          | pytest-cov     | ≥80%      |
| Types             | mypy (strict)  | 0 errors  |
| Lint              | ruff           | 0 errors  |

---

## Deployment Constraints

- **Serverless**: All deployments target Cloud Run
- **Stateless**: No local state; use external stores
- **Async-First**: All I/O operations use async/await
- **Health Checks**: `/health` endpoint required

---

**Version**: 1.0.0 | **Parent Constitution**: ADE v1.0.0
