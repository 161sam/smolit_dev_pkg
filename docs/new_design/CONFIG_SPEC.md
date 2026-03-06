
# Configuration Specification

This document defines the configuration format for smolit_dev_pkg.

---

# Configuration Files

Main configuration file:

````

smolit.config.yaml

```

Optional directories:

```

configs/workers/
configs/routing/
configs/models/

````

---

# Global Config

```yaml
version: 2

structurer:
  provider: local-openai
  base_url: http://localhost:1234/v1
  model: qwen-coder

supervisor:
  provider: codex
  model: codex-latest
````

---

# Worker Config

```yaml
workers:

  codex_standard:
    provider: codex
    role: standard

  claude_complex:
    provider: claude
    role: complex

  openhands_docs:
    provider: openhands
    role: docs-agent
    mode: manual
    model: qwen-coder
```

---

# Routing Rules

```yaml
routing:

  complexity_rules:

    - if: "task.complexity == 'low'"
      use: codex_standard

    - if: "task.complexity == 'high'"
      use: claude_complex

    - if: "task.type == 'documentation'"
      use: openhands_docs
```

---

# Worker Modes

```
auto
manual
```

---

# Tool Permissions

```yaml
tools:

  read_code: true
  write_code: true
  run_tests: true
  git: true
```

---

# OpenHands Instances

```yaml
openhands_instances:

  ui_agent:
    model: deepseek-coder
    workspace: gui/

  docs_agent:
    model: qwen-coder
    workspace: docs/
```

---

# Environment Variables

```
LM_BASE_URL
OPENAI_API_KEY
ANTHROPIC_API_KEY
CODEX_API_KEY
```

---

# Validation

Configuration is validated during startup.

Invalid configs stop execution.


