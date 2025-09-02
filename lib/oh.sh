#!/usr/bin/env bash
# lib/oh.sh - OpenHands specific functions and health checks
set -Eeuo pipefail
IFS=$'\n\t'

# ===== Health Checks =====
health() {
  banner
  local ok=0
  for url in \
    "http://127.0.0.1:$OH_PORT" \
    "http://127.0.0.1:$SEQ_PORT/healthz" \
    "http://127.0.0.1:$MEM_PORT/healthz" \
    "http://127.0.0.1:$BRIDGE_PORT/healthz"
  do
    if curl -fsS "$url" >/dev/null 2>&1; then
      echo -e "  ✓ $url"
      ok=$((ok+1))
    else
      echo -e "  ✗ $url"
    fi
  done
  [[ $ok -ge 1 ]] || return 1
}

# ===== Stack Management Commands =====
cmd_up() {
  start_openhands
  start_bridge
  open_browser
}

cmd_start() {
  start_openhands
  start_bridge
  tail_logs
}

cmd_stop() {
  stop_bridge
  stop_openhands
}

cmd_status() {
  health || true
}

cmd_logs() {
  if [[ "${1:-}" == "-f" ]]; then 
    tail_logs
  else 
    echo "$LOG_DIR"
  fi
}

# Register commands
sd_register "up" "Stack im Hintergrund + Browser öffnen" cmd_up
sd_register "start" "Stack starten & Logs im Vordergrund folgen" cmd_start
sd_register "stop" "Stack stoppen (Bridge + OpenHands)" cmd_stop
sd_register "status" "Health-Checks" cmd_status
sd_register "logs" "Log-Verzeichnis anzeigen (mit -f: folgen)" cmd_logs
