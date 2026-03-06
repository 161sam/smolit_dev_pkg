
# Worker Model

This document defines the worker architecture used in smolit_dev_pkg.

---

# Worker Philosophy

Workers are **specialized execution agents**.

They do not perform orchestration.

They only:

- execute tasks
- report results
- request clarification if needed

Routing decisions are handled by the Supervisor.

---

# Worker Types

| Worker | Purpose |
|------|------|
Codex | standard code tasks
Claude | complex reasoning
OpenHands | interactive agent tasks
Local | deterministic tools

---

# Worker Interface

All workers implement the same interface.

````

Worker
├ execute(task)
├ status()
├ capabilities()
└ shutdown()

````

---

# Worker Specification

Example worker definition:

```json
{
  "id": "codex-standard",
  "provider": "codex",
  "role": "standard",
  "capabilities": [
    "read_code",
    "write_code",
    "run_tests"
  ]
}
````

---

# OpenHands Worker

OpenHands workers are **instance based**.

Example:

```
openhands-docs
openhands-ui
openhands-research
```

Each instance has:

* workspace scope
* tool permissions
* model
* prompt template

---

# Worker Roles

```
standard
complex
ui-agent
docs-agent
analysis
reviewer
```

---

# Worker Lifecycle

```
init
ready
running
completed
error
shutdown
```

---

# Worker Capabilities

Examples:

```
read_code
write_code
git
tests
browser
analysis
documentation
```

Capabilities are used by the Supervisor to choose workers.

---

# Worker Isolation

Workers run in isolated environments:

Possible isolation layers:

```
docker
containerd
firecracker
sandbox
```

---

# Worker Communication

Workers communicate with the Supervisor via:

```
JSON RPC
HTTP
WebSocket
```

---

# Worker Pools

Workers can run in pools.

Example:

```
codex: 4 instances
claude: 2 instances
openhands: dynamic
```

---

# Error Handling

Worker failures trigger:

```
retry
reroute
escalation
fallback
```

---

# Worker Metrics

Collected metrics:

```
execution time
token usage
success rate
error rate
```

These metrics help optimize routing.



