# smolit_dev_pkg — Architecture v2

## Purpose

Architecture v2 introduces a **clear multi-agent orchestration model** for `smolit_dev_pkg`.

Goals:

- deterministic task orchestration
- clear separation of responsibilities
- scalable worker model
- local-first AI usage
- IDE integration readiness
- plugin-driven extensibility

This replaces the previous architecture where OpenHands handled prompt structuring and Claude acted as supervisor.

---

# Architecture Overview

```

User
│
│
▼
Prompt Structurer (Local LLM / LM Studio)
│
│ normalized task specification
▼
Supervisor (Codex)
│
│ task routing
│
├───────────────┬────────────────┬───────────────────┐
│               │                │                   │
▼               ▼                ▼                   ▼
Codex Worker   Claude Worker   OpenHands Pool     Local Tools
(Standard)     (Complex)       (multi instances)   (shell/git/tests)

```

---

# Core Principles

## 1 Local-First AI

Prompt structuring happens locally via:

- LM Studio
- OpenAI compatible API
- Local models

Benefits:

- privacy
- deterministic behaviour
- lower cost
- faster prompt iteration

---

## 2 Supervisor-Driven Orchestration

The **Supervisor (Codex)** controls:

- task decomposition
- worker routing
- retry logic
- validation
- result aggregation

Workers do not decide routing.

---

## 3 Worker Specialization

Workers are specialized:

| Worker | Purpose |
|------|------|
Codex | fast standard tasks
Claude | complex reasoning tasks
OpenHands | interactive agents
Local Tools | deterministic execution

---

## 4 Multi-Instance Agents

OpenHands workers are **instance based**, not global.

Example:

```

openhands-ui
openhands-docs
openhands-refactor
openhands-research

````

Each instance has:

- role
- tools
- workspace scope
- model
- permissions

---

# Core Components

## Prompt Structurer

Responsibility:

- normalize user intent
- generate structured tasks
- classify complexity

Example Output

```json
{
  "goal": "Add OpenHands multi instance workers",
  "complexity": "high",
  "tasks": [
    {"type":"analysis"},
    {"type":"implementation"},
    {"type":"documentation"}
  ]
}
````

---

## Supervisor

The Supervisor:

* assigns workers
* monitors execution
* resolves conflicts
* aggregates results

Primary model:

```
Codex
```

Fallback:

```
Claude
```

---

## Worker Layer

Workers implement a **unified interface**.

Worker types:

```
codex
claude
openhands
local
```

Capabilities example:

```
read_code
write_code
run_tests
browser
git
analysis
```

---

## Tool Layer

Deterministic actions run through tools.

Examples:

```
git
docker
tests
linters
build tools
```

Tools are **not LLM driven**.

---

# Execution Flow

```
User Request
   │
   ▼
Prompt Structurer
   │
   ▼
Structured Task
   │
   ▼
Supervisor
   │
   ▼
Worker Assignment
   │
   ▼
Execution
   │
   ▼
Validation
   │
   ▼
Result
```

---

# OpenHands Worker Pool

Multiple OpenHands instances can run concurrently.

Example configuration:

```
openhands-docs
openhands-ui
openhands-refactor
```

Supervisor may dynamically spawn instances.

---

# Auto Mode vs Manual Mode

## Auto Mode

Supervisor configures the worker automatically.

Used for:

* dynamic tasks
* autonomous workflows

## Manual Mode

User controls configuration.

Used for:

* experiments
* fine tuning
* deterministic behavior

---

# Future Extensions

Architecture v2 prepares the system for:

* IDE integration
* distributed agents
* plugin ecosystem
* secure execution sandboxes
* multi-machine orchestration

---

# Directory Structure

```
src/
  core/
  supervisor/
  structurer/
  workers/
  tools/

configs/
  workers/
  routing/

docs/
  architecture/

plugins/
```

---

# Version

Architecture Version

```
2.0
```

