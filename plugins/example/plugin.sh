#!/usr/bin/env bash
# plugins/example/plugin.sh - Enhanced demo plugin for sd CLI
set -Eeuo pipefail
IFS=$'\n\t'

# ===== Plugin Functions =====
example_echo() { 
  echo "Hello from plugin: $*"
  echo "Available plugin API functions:"
  echo "  sd_log, sd_warn, sd_die, sd_bridge_send, sd_config_get/set"
}

example_workspace() {
  echo "Current workspace: $WORKSPACE"
  echo "Configuration dir: $CONF_DIR"
  echo "Available commands: ${!SD_CMDS[*]}" | tr ' ' '\n' | sort
}

example_config() {
  local action="${1:-get}"
  local key="${2:-EXAMPLE_KEY}"
  local value="${3:-}"
  
  case "$action" in
    get)
      local val="$(sd_config_get "$key")"
      [[ -n "$val" ]] && echo "$key=$val" || echo "$key not set"
    ;;
    set)
      [[ -n "$value" ]] || die "Usage: sd example:config set KEY VALUE"
      sd_config_set "$key" "$value"
      echo "Set $key=$value"
    ;;
    *)
      echo "Usage: sd example:config {get|set} [key] [value]"
    ;;
  esac
}

example_bridge() {
  local prompt="${*:-Hello from example plugin via bridge!}"
  sd_log "Sending to bridge: $prompt"
  sd_bridge_send "$prompt"
}

example_docker() {
  if command -v docker >/dev/null 2>&1; then
    sd_docker_run --rm hello-world
  else
    sd_warn "Docker not available"
  fi
}

example_template() {
  local name="${1:-example}"
  local dest="$WORKSPACE/.openhands/example_$name.md"
  
  # Create a simple template
  mkdir -p "$(dirname "$dest")"
  cat > "$dest" << 'EOF'
# Example Template

Project: {{PROJECT}}
Workspace: {{WORKSPACE}}
Date: {{DATE_ISO}}

This is an example template rendered by the plugin system.
EOF
  
  sd_template_render "example_$name.md" "$dest" 2>/dev/null || {
    # Manual template replacement if sd_template_render not available
    local proj="$(basename "$WORKSPACE")"
    local now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    sed -i "s|{{PROJECT}}|$proj|g; s|{{WORKSPACE}}|$WORKSPACE|g; s|{{DATE_ISO}}|$now|g" "$dest"
  }
  
  echo "Template rendered: $dest"
  head -n 10 "$dest"
}

# ===== Register Plugin Commands =====
sd_register "example:echo" "Demo-Plugin sagt hallo" example_echo
sd_register "example:workspace" "Zeigt Workspace und verfügbare Kommandos" example_workspace
sd_register "example:config" "Config get/set demo" example_config
sd_register "example:bridge" "Send message via bridge" example_bridge
sd_register "example:docker" "Run hello-world container" example_docker
sd_register "example:template" "Template rendering demo" example_template
