
# IDE Integration Plan

This document describes how smolit_dev_pkg integrates with code editors.

---

# Goal

Allow developers to use smolit_dev_pkg directly inside modern IDEs.

Target editors:

- VS Code
- Zed
- JetBrains IDEs
- Neovim

---

# Core Requirement

IDE integration requires a local daemon.

```

sd daemon

```

Responsibilities:

- manage workers
- expose API
- maintain sessions

---

# API Layer

The daemon exposes:

```

HTTP API
WebSocket events
MCP server

```

---

# VS Code Integration

VS Code extension features:

```

sidebar agent panel
worker status
task runner
logs viewer
send selection to AI

```

Architecture:

```

VS Code Extension
│
▼
sd daemon
│
▼
workers

```

---

# Zed Integration

Zed integration options:

1. MCP server
2. agent server
3. native extension (Rust)

Recommended path:

```

MCP server first

```

---

# Editor Commands

Examples:

```

sd.runTask
sd.openSession
sd.sendSelection
sd.fixFile
sd.generateDocs

```

---

# Editor UI

Sidebar panels:

```

Workers
Tasks
Sessions
Logs

```

---

# Session Model

Each IDE task creates a session.

Session contains:

```

prompt
workers
actions
results

```

Sessions can be replayed.

---

# Security

IDE plugins must not:

- expose API keys
- execute unsafe commands
- bypass sandbox restrictions

---

# Future

Planned features:

```

multi workspace support
distributed workers
remote agents
team collaboration
```
```

