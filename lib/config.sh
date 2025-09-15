#!/usr/bin/env bash
# lib/config.sh - Configuration management, ENV layering, XDG paths
set -Eeuo pipefail
IFS=$'\n\t'

# Idempotent sourcing guard
if [[ "${SD_CONFIG_SH_LOADED:-0}" = "1" ]]; then
  return 0
fi
SD_CONFIG_SH_LOADED=1

# ===== XDG Paths (inherit from parent if set) =====
if [[ -z "${CONF_DIR:-}" ]]; then
  XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

  CONF_DIR="$XDG_CONFIG_HOME/smolit_dev"
  STATE_DIR="$XDG_STATE_HOME/smolit_dev"
  CACHE_DIR="$XDG_CACHE_HOME/smolit_dev"
  LOG_DIR="$STATE_DIR/logs"
  PID_DIR="$STATE_DIR/pids"

  # Ensure directories exist
  mkdir -p "$CONF_DIR" "$STATE_DIR" "$CACHE_DIR" "$LOG_DIR" "$PID_DIR"
fi

# ===== ENV File Loading =====
ENV_FILE="${ENV_FILE:-$CONF_DIR/.env}"
[[ -f "$ENV_FILE" ]] && set -a && . "$ENV_FILE" && set +a

# ===== Core Environment Variables (with defaults) =====
WORKSPACE="${WORKSPACE:-$PWD}"
WORKSPACE_DEFAULT="${WORKSPACE_DEFAULT:-$HOME/OpenHands_Workspace}"

LM_BASE_URL="${LM_BASE_URL:-http://127.0.0.1:1234/v1}"
OH_PORT="${OH_PORT:-3311}"
SEQ_PORT="${SEQ_PORT:-8811}"
MEM_PORT="${MEM_PORT:-8812}"
BRIDGE_PORT="${BRIDGE_PORT:-8815}"
MEM_FILE="${MEM_FILE:-$HOME/.mcp/memory/memory_shared.json}"

OH_IMAGE="${OH_IMAGE:-openhands/supergateway:latest}"
OH_NAME="${OH_NAME:-sd_oh}"
SD_LLM_MODEL="${SD_LLM_MODEL:-}"

# Security/Permissions
SD_BYPASS_PERMISSIONS="${SD_BYPASS_PERMISSIONS:-}"
SD_ALLOWED_TOOLS="${SD_ALLOWED_TOOLS:-sequential-thinking,memory-shared,memory,codex-bridge}"

# Binary paths and templates (resolve relative to this file)
# Determine directories robustly without relying on external definitions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LIB_DIR/.." && pwd)"

# Keep SELF_DIR for backward compatibility (points to ROOT_DIR)
SELF_DIR="${SELF_DIR:-$ROOT_DIR}"

BRIDGE_BIN="${SD_BRIDGE_BIN:-$ROOT_DIR/bin/bridge.mjs}"
POSTINSTALL_BIN="$ROOT_DIR/bin/postinstall.mjs"

# Template directory
TEMPLATE_DIR="${SD_TEMPLATE_DIR:-$ROOT_DIR/templates}"

# ===== Config Helpers =====
write_env_kv() {
  local key="$1" val="$2"
  mkdir -p "$(dirname "$ENV_FILE")"; touch "$ENV_FILE"
  if grep -qE "^${key}=" "$ENV_FILE"; then
    local esc="${val//\//\\/}"
    sed "${SED_INPLACE[@]}" "s|^${key}=.*|${key}=${esc}|" "$ENV_FILE"
  else
    printf "%s=%s\n" "$key" "$val" >> "$ENV_FILE"
  fi
}

# ===== OpenHands Directory Setup =====
OH_DIR="$WORKSPACE/.openhands"
MICRO_DIR="$OH_DIR/microagents"
PROMPTS_DIR="$OH_DIR/prompts"

ensure_oh_dirs() {
  mkdir -p "$MICRO_DIR" "$PROMPTS_DIR" "$OH_DIR/logs"
  if [[ ! -f "$MICRO_DIR/repo.md" ]]; then
    cat >"$MICRO_DIR/repo.md" <<'MD'
# Repo Microagent Context (repo.md)
<repo>
  <name>{{PROJECT}}</name>
  <root>{{WORKSPACE}}</root>
  <langs>python, typescript, bash</langs>
  <build>npm/yarn + uvicorn/pytest</build>
  <constraints>
    - keine Platzhalter, lauffähiger Code
    - backward-compatible, keine destructive ops ohne Backup
  </constraints>
  <contacts>
    - owner: huckle lab
  </contacts>
</repo>
MD
    # Replace placeholders
    local proj="$(basename "$WORKSPACE")"
    local w_esc="$(_escape_sed "$WORKSPACE")"
    sed ${SED_INPLACE[@]} \
      -e "s|{{PROJECT}}|$proj|g" \
      -e "s|{{WORKSPACE}}|$w_esc|g" \
      "$MICRO_DIR/repo.md"
    log "Auto: .openhands/microagents/repo.md erzeugt."
  fi
}

# ===== Template Rendering =====
_render_template() {
  # _render_template <template-name> <dest-file>
  local name="$1"; local dest="$2"
  local src="$TEMPLATE_DIR/$name"
  mkdir -p "$(dirname "$dest")"
  
  if [[ ! -f "$src" ]]; then
    # Fallback if template missing
    echo "# ${name%.*} — {{PROJECT}} @ {{DATE_ISO}}" > "$dest"
  else
    cp "$src" "$dest"
  fi
  
  # Replace placeholders
  local proj="$(basename "$WORKSPACE")"
  local now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local w_esc="$(_escape_sed "$WORKSPACE")"
  local l_esc="$(_escape_sed "$LM_BASE_URL")"
  
  sed "${SED_INPLACE[@]}" \
    -e "s|{{PROJECT}}|$proj|g" \
    -e "s|{{WORKSPACE}}|$w_esc|g" \
    -e "s|{{LM_BASE_URL}}|$l_esc|g" \
    -e "s|{{DATE_ISO}}|$now|g" \
    "$dest"
}
