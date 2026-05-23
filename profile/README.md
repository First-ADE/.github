# First ADE

<p align="center">
  <img src="https://img.shields.io/badge/Initiative-Axiom--Driven%20Engineering-A855F7?style=for-the-badge&logo=github&logoColor=white" alt="ADE Initiative Badge" />
  <img src="https://img.shields.io/badge/Focus-AI--Native%20Systems-3B82F6?style=for-the-badge&logo=openai&logoColor=white" alt="AI Focus Badge" />
  <img src="https://img.shields.io/badge/OSS-Advocacy%20%26%20Research-10B981?style=for-the-badge&logo=git&logoColor=white" alt="OSS Advocacy Badge" />
</p>

---

## 🎯 Our Mission

**First ADE** is an Open Source Software advocacy group and personal initiative dedicated to pioneering **Axiom-Driven Engineering (ADE)** practices for developing **AI-Native Applications**. 

As artificial intelligence moves from static prompts to autonomous, agentic workflows, software engineering must transition from *probabilistic testing* to *deterministic runtime validation*. We champion the integration of strict, CI-enforced formal invariants (axioms) directly into the development cycle of AI agents, ensuring LLM-native tools remain secure, robust, and completely verifiable.

---

## 💡 The 3 Pillars of AI-Native ADE

To bridge the gap between non-deterministic AI generation and deterministic software reliability, our research champions three core pillars:

```text
    ┌─────────────────────────────────────────────────────────┐
    │              Axiom-Driven Engineering (ADE)             │
    └────────────────────────────┬────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
 ┌───────────────┐       ┌───────────────┐       ┌───────────────┐
 │  1. SYSTEM    │       │   2. AGENTIC  │       │  3. GRANULAR  │
 │  INVARIANTS   │       │  DETERMINISM  │       │  GOVERNANCE   │
 └───────┬───────┘       └───────┬───────┘       └───────┬───────┘
         │                       │                       │
         ▼                       ▼                       ▼
  CI-Enforced Code       Boundary & Prompt      Architects/Devs
  & Script Contracts      Output Contracts      Prompt-As-Code
```

### 🛡️ 1. Formal System Invariants
Traditional codebase quality is verified post-facto. Under ADE, critical properties are defined as **unbreakable mathematical invariants** (Axioms) checked on every git commit. 
- *Axiom A1-A3*: Strict shebang checks, file permissions, and file presence.
- *Axiom A4*: Structural integrity verification of automated workflows.
- *Enforcement*: Automated local validations prevent broken states from ever hitting the trunk.

### ⚙️ 2. Agentic Determinism (Cognitive Contracts)
AI Native applications are inherently non-deterministic. ADE addresses this by creating **runtime validation envelopes** (boundary checkers) that wrapping model interfaces.
- *Prompt Contracts*: Validating model prompts and system instructions as code.
- *Output Envelopes*: Programmatic validation of structured LLM outputs against strict schemas, catching hallucinations before execution.

### 👥 3. Granular Governance (Prompt-As-Code)
Prompts and model configurations are code. We advocate for peer-reviewed, team-level governance over AI knowledge bases and instructions.
- *Structured Access*: Mapped organization-wide roles (`Architects` vs `Developers`) to enforce code reviews on model parameters.
- *Traceability*: Complete accountability of prompt changes and benchmark evaluations before merging.

---

## 📂 Core Repository Index

Our open-source initiative is structured across three fundamental repositories:

| Repository | Primary Purpose | Primary Tech | Access | Status |
| :--- | :--- | :--- | :--- | :--- |
| [📂 .github](https://github.com/First-ADE/.github) | **Organization Core**: Global workflows, CI shebang validators, and community standards. | Shell / PowerShell | `Public` | ![Active](https://img.shields.io/badge/Status-Active-success?style=flat-square) |
| [📂 first-ade](https://github.com/First-ADE/first-ade) | **Core SDK & Framework**: Reusable boundary checking, model benchmarks, and ADE validators. | Python / Shell | `Public` | ![Beta](https://img.shields.io/badge/Status-Beta-orange?style=flat-square) |
| [📂 Constitution-MCP](https://github.com/First-ADE/Constitution-MCP) | **Agent Core**: Model Context Protocol (MCP) server defining agent constitutions and policies. | Python | `Private` | ![Secure](https://img.shields.io/badge/Status-Secure-blue?style=flat-square) |

---

## 🤝 Getting Started & Onboarding

Whether you are a developer looking to integrate ADE guardrails or an OSS advocate interested in AI determinism, we welcome your collaboration!

- **Onboarding Guide**: Check out our global [README.md](https://github.com/First-ADE/.github/blob/main/README.md) to understand local development.
- **Repository Invariants**: Familiarize yourself with our [AXIOMS.md](https://github.com/First-ADE/.github/blob/main/AXIOMS.md) which defines the active system rules.
- **Code of Conduct**: We hold ourselves to professional, welcoming collaboration. Read our [CODE_OF_CONDUCT.md](https://github.com/First-ADE/.github/blob/main/.github/CODE_OF_CONDUCT.md).
- **Contributing**: Ready to make a change? Review the standard checklist inside our [Pull Request Template](https://github.com/First-ADE/.github/blob/main/.github/pull_request_template.md).

---

<p align="center">
  <sub>Built with 💜 by the First-ADE OSS Advocacy Group. "Rigorous AI requires rigorous engineering."</sub>
</p>
