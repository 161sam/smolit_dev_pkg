
# Migration Plan

This document describes the migration from Architecture v1 to Architecture v2.

---

# Goals

- remove legacy orchestration
- introduce supervisor model
- support multi-instance OpenHands workers
- enable IDE integration

---

# Phase 1 — Stabilization

Tasks:

- remove legacy CLI paths
- fix module inconsistencies
- unify configuration loading
- implement worker interface

Expected result:

Stable core architecture.

---

# Phase 2 — Supervisor Introduction

Tasks:

- introduce supervisor component
- integrate Codex supervisor
- implement worker routing

---

# Phase 3 — Structurer

Tasks:

- implement prompt structurer
- integrate LM Studio
- normalize task specification

---

# Phase 4 — OpenHands Workers

Tasks:

- implement OpenHands worker adapter
- support multiple instances
- implement auto/manual modes

---

# Phase 5 — Routing Engine

Tasks:

- implement routing rules
- complexity classification
- worker selection

---

# Phase 6 — Tool Integration

Tasks:

- integrate git
- integrate test runners
- integrate build systems

---

# Phase 7 — IDE Integration Preparation

Tasks:

- implement daemon mode
- add HTTP API
- add websocket events
````

---
