#!/usr/bin/env bash
# plugins/example/plugin.sh - Demo plugin for sd CLI
set -Eeuo pipefail
IFS=$'\n\t'

example_echo() { 
  echo "Hello from plugin: $*"; 
}

example_workspace() {
  echo "Current workspace: $WORKSPACE"
  echo "Available commands: ${!SD_CMDS[*]}" | tr ' ' '\n' | sort
}

# Register plugin commands
sd_register "example:echo" "Demo-Plugin sagt hallo" example_echo
sd_register "example:workspace" "Zeigt Workspace und verfügbare Kommandos" example_workspace