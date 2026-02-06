# Contributing to First ADE

Thank you for your interest in contributing to First ADE! This guide outlines our contribution process and standards.

## 🎯 Axiom Driven Engineering Principles

All contributions should align with our core methodology:

1. **Trace to Axioms** — Changes should be justifiable from first principles
2. **Spec Before Code** — Write specifications before implementation
3. **Document Rationale** — Explain *why*, not just *what*

## 🚀 Getting Started

### Prerequisites

- Git
- Python 3.11+ (for Speckit)
- [uv](https://docs.astral.sh/uv/) for package management

### Setup

1. Fork the repository
2. Clone your fork locally
3. Install dependencies following the project's README

## 📝 Contribution Workflow

### 1. Create an Issue First

Before starting work:
- Check existing issues for duplicates
- Create a new issue describing your proposed change
- Wait for maintainer feedback on larger changes

### 2. Branch Naming

Use descriptive branch names:
```
feature/<short-description>
fix/<issue-number>-<short-description>
docs/<what-you're-documenting>
```

### 3. Spec-Driven Development

For significant changes:
```bash
/speckit.specify    # Define what you're building
/speckit.plan       # Create implementation plan
/speckit.tasks      # Break down into tasks
/speckit.implement  # Execute the plan
```

### 4. Commit Messages

Follow conventional commits:
```
type(scope): description

[optional body]

[optional footer]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### 5. Pull Requests

- Fill out the PR template completely
- Link to related issues
- Ensure CI passes
- Request review from maintainers

## ✅ Code Standards

- Follow the project's existing style
- Write tests for new functionality
- Update documentation as needed
- Keep PRs focused and reasonably sized

## 🔍 Review Process

1. All PRs require at least one maintainer review
2. Address feedback promptly
3. Squash commits before merge (if requested)

## 📖 Architecture Decision Records (ADRs)

For architectural changes:
- Create an ADR in `docs/adr/`
- Reference the governing axioms
- Get approval before implementation

---

Questions? Open an issue or reach out to the maintainers!
