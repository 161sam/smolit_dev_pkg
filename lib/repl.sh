#!/usr/bin/env bash
# lib/repl.sh - REPL and send functions
set -Eeuo pipefail
IFS=$'\n\t'

# Idempotent sourcing guard
if [[ "${SD_REPL_SH_LOADED:-0}" = "1" ]]; then
  return 0
fi
SD_REPL_SH_LOADED=1

# ===== REPL / Send Shortcuts =====
start_repl() {
  start_bridge
  echo "sd REPL — sende Zeilen an Bridge. Befehle: :quit, :help, :file <path>"
  while IFS= read -r -e line; do
    case "$line" in
      ":quit"|":q") break ;;
      ":help") echo ":file <path> — sendet Dateiinhalt /workspace-relativ"; continue ;;
      ":file "*) 
        local f="${line#:file }"
        [[ -f "$f" ]] || { echo "Datei fehlt: $f"; continue; }
        send_to_bridge_file "$(_realpath "$f")"
        continue
      ;;
      "") continue ;;
      *) send_to_bridge_prompt "$line" ;;
    esac
  done
}

send_init() {
  local text="${*:-}"
  [[ -n "$text" ]] || die "Usage: sd send init \"GOAL: …\""
  start_bridge
  send_to_bridge_prompt "$text"
}

send_change() {
  local text="${*:-}"
  [[ -n "$text" ]] || die "Usage: sd send c \"Bitte ändere …\""
  start_bridge
  send_to_bridge_prompt "$text"
}

cmd_send() {
  local sub="${1:-}"; shift || true
  case "${sub:-}" in
    init) send_init "$@";;
    c)    send_change "$@";;
    *)    [[ -n "${sub:-}" ]] && send_to_bridge_prompt "$sub $*" || die "Usage: sd send {init|c} <text>" ;;
  esac
}

# Register commands
sd_register "start-repl" "interaktive Session (GUI parallel nutzbar)" start_repl
sd_register "send:init" "Initial-/Ziel-Prompt senden" send_init
sd_register "send:c" "Änderungs-/Follow-up-Prompt senden" send_change
sd_register "c" "Kurzform für 'sd send c …'" send_change
