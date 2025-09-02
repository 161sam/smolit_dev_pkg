#!/usr/bin/env bash
# lib/mcp.sh - MCP and project setup functions
set -Eeuo pipefail
IFS=$'\n\t'

# ===== MCP / Project Setup =====
project_init() {
  local cfg="$WORKSPACE/.claude/settings.json"
  mkdir -p "$WORKSPACE/.claude"
  if [[ -f "$cfg" ]]; then
    log "Settings vorhanden: $cfg"
  else
    cat >"$cfg" <<'JSON'
{
  "mcpServers": {
    "sequential-thinking": { "type": "sse", "url": "http://host.docker.internal:8811/sse" },
    "server-memory":       { "type": "sse", "url": "http://host.docker.internal:8812/sse" }
  }
}
JSON
    log "Minimal .claude/settings.json erzeugt."
  fi
}

mcp_status() {
  echo "MCP Status:"
  health || true
  if command -v claude >/dev/null 2>&1; then
    echo "Claude '/mcp' (gekürzt):"
    set +e
    claude -p "/mcp" --print 2>/dev/null | sed -n '1,40p'
    set -e
  else
    echo "(Hinweis) 'claude' CLI nicht gefunden – überspringe '/mcp'."
  fi
}

cmd_init_repo() {
  project_init
  ensure_oh_dirs
  [[ -f "$WORKSPACE/.openhands/index_repo.txt" ]] || : > "$WORKSPACE/.openhands/index_repo.txt"
  log "Repo initialisiert: .claude/settings.json & .openhands/"
}

# Register commands
sd_register "project:init" ".claude/settings.json (MCP SSE) erzeugen" project_init
sd_register "init" "Projekt-Setup (.claude + .openhands) anlegen" cmd_init_repo
sd_register "mcp:status" "MCP-Status (healthz + ggf. 'claude -p \"/mcp\"')" mcp_status