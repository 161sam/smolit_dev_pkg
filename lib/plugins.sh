#!/usr/bin/env bash
# lib/plugins.sh - Plugin management system
set -Eeuo pipefail
IFS=$'\n\t'

# ===== Plugin State Management =====
declare -A PLUGIN_STATE  # enabled/disabled status
declare -A PLUGIN_PATHS  # plugin name -> path mapping
declare -A PLUGIN_META   # plugin metadata

# Initialize plugin state file
init_plugin_state() {
  local state_file="$CONF_DIR/plugin_state.json"
  [[ -f "$state_file" ]] || echo '{}' > "$state_file"
}

# Load plugin state
load_plugin_state() {
  local state_file="$CONF_DIR/plugin_state.json"
  [[ -f "$state_file" ]] || return 0
  
  if command -v jq >/dev/null 2>&1; then
    while IFS= read -r line; do
      local name status
      name="$(echo "$line" | cut -d: -f1)"
      status="$(echo "$line" | cut -d: -f2)"
      PLUGIN_STATE["$name"]="$status"
    done < <(jq -r 'to_entries[] | "\(.key):\(.value)"' "$state_file" 2>/dev/null || true)
  fi
}

# Save plugin state
save_plugin_state() {
  local state_file="$CONF_DIR/plugin_state.json"
  mkdir -p "$(dirname "$state_file")"
  
  if command -v jq >/dev/null 2>&1; then
    local json_content="{}"
    for name in "${!PLUGIN_STATE[@]}"; do
      json_content="$(echo "$json_content" | jq --arg name "$name" --arg status "${PLUGIN_STATE[$name]}" '. + {($name): $status}')"
    done
    echo "$json_content" > "$state_file"
  else
    # Fallback without jq
    echo "{" > "$state_file"
    local first=true
    for name in "${!PLUGIN_STATE[@]}"; do
      [[ "$first" == "true" ]] && first=false || echo "," >> "$state_file"
      printf '  "%s": "%s"' "$name" "${PLUGIN_STATE[$name]}" >> "$state_file"
    done
    echo "" >> "$state_file"
    echo "}" >> "$state_file"
  fi
}

# ===== Plugin Discovery =====
discover_plugins() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  
  for plugin_dir in "$dir"/*/; do
    [[ -d "$plugin_dir" ]] || continue
    local plugin_name="$(basename "$plugin_dir")"
    local plugin_file="$plugin_dir/plugin.sh"
    
    if [[ -f "$plugin_file" ]]; then
      PLUGIN_PATHS["$plugin_name"]="$plugin_file"
      
      # Load metadata if exists
      local meta_file="$plugin_dir/plugin.json"
      if [[ -f "$meta_file" ]]; then
        PLUGIN_META["$plugin_name"]="$meta_file"
      fi
      
      # Set default state if not set
      [[ -n "${PLUGIN_STATE[$plugin_name]:-}" ]] || PLUGIN_STATE["$plugin_name"]="enabled"
    fi
  done
}

# ===== Enhanced Plugin Loading =====
load_plugins_enhanced() {
  local dir="$1"
  
  init_plugin_state
  load_plugin_state
  discover_plugins "$dir"
  
  for name in "${!PLUGIN_PATHS[@]}"; do
    local status="${PLUGIN_STATE[$name]:-enabled}"
    local path="${PLUGIN_PATHS[$name]}"
    
    if [[ "$status" == "enabled" && -f "$path" ]]; then
      if bash -n "$path" 2>/dev/null; then
        source "$path"
        log "Plugin loaded: $name"
      else
        warn "Plugin $name has syntax errors, skipping"
        PLUGIN_STATE["$name"]="disabled"
      fi
    elif [[ "$status" == "disabled" ]]; then
      log "Plugin $name disabled"
    fi
  done
  
  save_plugin_state
}

# ===== Plugin Management Commands =====
plugin_list() {
  echo "Available plugins:"
  echo "Name              Status    Path"
  echo "================= ========= ===================================="
  
  for name in "${!PLUGIN_PATHS[@]}"; do
    local status="${PLUGIN_STATE[$name]:-enabled}"
    local path="${PLUGIN_PATHS[$name]}"
    printf "%-17s %-9s %s\n" "$name" "$status" "$path"
  done
  
  if [[ ${#PLUGIN_PATHS[@]} -eq 0 ]]; then
    echo "No plugins found."
    echo
    echo "Plugin directories:"
    echo "  ~/.config/smolit_dev/plugins/"
    echo "  $WORKSPACE/.sd/plugins/"
  fi
}

plugin_enable() {
  local name="${1:-}"
  [[ -n "$name" ]] || die "Usage: sd plugin enable <n>"
  
  if [[ -n "${PLUGIN_PATHS[$name]:-}" ]]; then
    PLUGIN_STATE["$name"]="enabled"
    save_plugin_state
    log "Plugin '$name' enabled. Run 'sd plugin reload' to activate."
  else
    die "Plugin '$name' not found"
  fi
}

plugin_disable() {
  local name="${1:-}"
  [[ -n "$name" ]] || die "Usage: sd plugin disable <n>"
  
  if [[ -n "${PLUGIN_PATHS[$name]:-}" ]]; then
    PLUGIN_STATE["$name"]="disabled"
    save_plugin_state
    log "Plugin '$name' disabled. Run 'sd plugin reload' to deactivate."
  else
    die "Plugin '$name' not found"
  fi
}

plugin_reload() {
  local name="${1:-}"
  
  if [[ -n "$name" ]]; then
    # Reload specific plugin
    if [[ -n "${PLUGIN_PATHS[$name]:-}" ]]; then
      local path="${PLUGIN_PATHS[$name]}"
      local status="${PLUGIN_STATE[$name]:-enabled}"
      
      if [[ "$status" == "enabled" ]]; then
        if bash -n "$path" 2>/dev/null; then
          source "$path"
          log "Plugin '$name' reloaded"
        else
          warn "Plugin '$name' has syntax errors"
        fi
      else
        log "Plugin '$name' is disabled"
      fi
    else
      die "Plugin '$name' not found"
    fi
  else
    # Reload all plugins
    log "Reloading all plugins..."
    
    # Clear existing commands registered by plugins
    for cmd in "${!SD_CMDS[@]}"; do
      if [[ "$cmd" =~ : ]]; then
        unset SD_CMDS["$cmd"]
      fi
    done
    
    # Reload from all directories
    load_plugins_enhanced "$CONF_DIR/plugins"
    load_plugins_enhanced "$WORKSPACE/.sd/plugins"
    
    log "Plugin reload complete"
  fi
}

plugin_create() {
  local name="${1:-}"
  [[ -n "$name" ]] || die "Usage: sd plugin create <n>"
  
  # Sanitize name
  name="$(echo "$name" | sed 's/[^a-zA-Z0-9_-]/_/g')"
  
  local plugin_dir="$CONF_DIR/plugins/$name"
  
  if [[ -d "$plugin_dir" ]]; then
    die "Plugin '$name' already exists at $plugin_dir"
  fi
  
  mkdir -p "$plugin_dir"
  
  # Create plugin.sh
  cat > "$plugin_dir/plugin.sh" << EOF
#!/usr/bin/env bash
# plugins/$name/plugin.sh - Generated plugin
set -Eeuo pipefail
IFS=\$'\\n\\t'

${name}_hello() {
  echo "Hello from $name plugin!"
  echo "Args: \$*"
  echo "Workspace: \$WORKSPACE"
}

${name}_info() {
  echo "Plugin: $name"
  echo "Version: 1.0.0" 
  echo "Author: \$(whoami)"
  echo "Created: \$(date)"
}

# Register plugin commands
sd_register "${name}:hello" "Say hello from $name plugin" ${name}_hello
sd_register "${name}:info" "Show $name plugin info" ${name}_info
EOF

  # Create plugin.json metadata
  cat > "$plugin_dir/plugin.json" << EOF
{
  "name": "$name",
  "version": "1.0.0",
  "description": "Generated plugin: $name",
  "author": "$(whoami)",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "commands": [
    "${name}:hello",
    "${name}:info"
  ],
  "dependencies": []
}
EOF

  # Create README.md
  cat > "$plugin_dir/README.md" << EOF
# $name Plugin

Generated plugin for smolit_dev CLI.

## Commands

- \`sd ${name}:hello\` - Say hello from $name plugin  
- \`sd ${name}:info\` - Show plugin information

## Development

Edit \`plugin.sh\` to add your functionality.
Use \`sd plugin test $name\` to test your plugin.

## Installation

This plugin is automatically available in your user plugin directory:
\`~/.config/smolit_dev/plugins/$name/\`
EOF

  chmod +x "$plugin_dir/plugin.sh"
  
  log "Plugin '$name' created at $plugin_dir"
  log "Commands:"
  log "  sd $name:hello  - Say hello"
  log "  sd $name:info   - Show info"
  log "  sd plugin reload - Activate plugin"
}

plugin_test() {
  local name="${1:-}"
  [[ -n "$name" ]] || die "Usage: sd plugin test <n>"
  
  if [[ -z "${PLUGIN_PATHS[$name]:-}" ]]; then
    die "Plugin '$name' not found"
  fi
  
  local path="${PLUGIN_PATHS[$name]}"
  
  echo "Testing plugin: $name"
  echo "Path: $path"
  echo
  
  # Syntax check
  echo "1. Syntax check..."
  if bash -n "$path"; then
    echo "   ✓ Syntax OK"
  else
    echo "   ✗ Syntax errors found"
    return 1
  fi
  
  # Source check (dry run)
  echo "2. Source test..."
  if (source "$path") 2>/dev/null; then
    echo "   ✓ Plugin sources without errors"
  else
    echo "   ✗ Plugin has runtime errors"
    return 1
  fi
  
  # Function check
  echo "3. Function registration..."
  local temp_cmds=()
  local old_register="$(declare -f sd_register)"
  sd_register() {
    temp_cmds+=("$1")
    echo "   → Registered: $1"
  }
  
  source "$path"
  
  # Restore original sd_register
  eval "$old_register"
  
  if [[ ${#temp_cmds[@]} -gt 0 ]]; then
    echo "   ✓ ${#temp_cmds[@]} command(s) registered"
  else
    echo "   ! No commands registered"
  fi
  
  echo
  echo "Plugin '$name' test completed successfully"
}

plugin_install() {
  local url="${1:-}"
  [[ -n "$url" ]] || die "Usage: sd plugin install <git-url>"
  
  # Extract plugin name from URL
  local name="$(basename "$url" .git)"
  local plugin_dir="$CONF_DIR/plugins/$name"
  
  if [[ -d "$plugin_dir" ]]; then
    read -r -p "Plugin '$name' exists. Overwrite? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || die "Installation cancelled"
    rm -rf "$plugin_dir"
  fi
  
  log "Installing plugin from $url..."
  
  if command -v git >/dev/null 2>&1; then
    git clone "$url" "$plugin_dir" || die "Git clone failed"
    
    # Remove .git directory
    rm -rf "$plugin_dir/.git"
    
    # Check if plugin.sh exists
    if [[ ! -f "$plugin_dir/plugin.sh" ]]; then
      die "Invalid plugin: plugin.sh not found"
    fi
    
    # Test plugin
    discover_plugins "$CONF_DIR/plugins"
    plugin_test "$name"
    
    log "Plugin '$name' installed successfully"
    log "Run 'sd plugin reload' to activate"
  else
    die "Git is required for plugin installation"
  fi
}

# ===== Plugin API Helpers =====
# These functions are available to plugins

sd_log() { log "$@"; }
sd_warn() { warn "$@"; }  
sd_die() { die "$@"; }

sd_bridge_send() {
  local prompt="$1"
  start_bridge
  send_to_bridge_prompt "$prompt"
}

sd_docker_run() {
  need docker
  docker run "$@"
}

sd_template_render() {
  local template="$1" dest="$2"
  _render_template "$template" "$dest"
}

sd_config_get() {
  local key="$1"
  grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d= -f2- || true
}

sd_config_set() {
  local key="$1" value="$2"
  write_env_kv "$key" "$value"
}

# ===== Register Commands =====
sd_register "plugin:list" "Show available plugins" plugin_list
sd_register "plugin:enable" "Enable a plugin" plugin_enable
sd_register "plugin:disable" "Disable a plugin" plugin_disable  
sd_register "plugin:reload" "Reload plugins" plugin_reload
sd_register "plugin:create" "Create a new plugin" plugin_create
sd_register "plugin:test" "Test a plugin" plugin_test
sd_register "plugin:install" "Install plugin from git" plugin_install

# ===== Enhanced Plugin Loading (replace simple load_plugins) =====
# Update core.sh to use this instead of the simple load_plugins
load_plugins() {
  load_plugins_enhanced "$1"
}
