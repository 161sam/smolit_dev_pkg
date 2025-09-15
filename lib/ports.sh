#!/usr/bin/env bash
# lib/ports.sh - Port checking utilities
set -Eeuo pipefail
IFS=$'\n\t'

# Idempotent sourcing guard
if [[ "${SD_PORTS_SH_LOADED:-0}" = "1" ]]; then
  return 0
fi
SD_PORTS_SH_LOADED=1

# ===== Port Checking =====
_port_in_use() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
  elif command -v ss >/dev/null 2>&1; then
    ss -lntH "( sport = :$port )" 2>/dev/null | grep -q .
  elif command -v netstat >/dev/null 2>&1; then
    netstat -an 2>/dev/null | grep -E "[\.\:]$port[[:space:]]" | grep -qi LISTEN
  else
    return 1
  fi
}

_port_info() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"$port" -sTCP:LISTEN | awk 'NR==1 || NR==2'
  elif command -v ss >/dev/null 2>&1; then
    ss -lntp "( sport = :$port )" 2>/dev/null | sed -n '1,2p'
  elif command -v netstat >/dev/null 2>&1; then
    netstat -an 2>/dev/null | grep -E "[\.\:]$port[[:space:]]" | sed -n '1,2p'
  fi
}

# ===== Commands =====
ports_doctor() {
  echo "Port-Check:"
  for p in "$OH_PORT" "$SEQ_PORT" "$MEM_PORT" "$BRIDGE_PORT"; do
    if _port_in_use "$p"; then
      echo "  ✗ Port $p belegt:"
      _port_info "$p"
    else
      echo "  ✓ Port $p frei"
    fi
  done
}

# Register command
sd_register "ports:doctor" "Port-Kollisionen prüfen" ports_doctor
