#!/usr/bin/env bash
# lib/core.sh - Core utilities, logging, dispatcher, plugin system
set -Eeuo pipefail
IFS=$'\n\t'

# ===== Colors (TTY-safe) =====
if [[ -t 1 ]]; then
  cCyan=$'\e[36m'; cYel=$'\e[33m'; cRed=$'\e[31m'; cDim=$'\e[2m'; cOff=$'\e[0m'
else
  cCyan=""; cYel=""; cRed=""; cDim=""; cOff=""
fi

# ===== Logging =====
log()   { echo -e "${cCyan}[sd]${cOff} $*"; }
warn()  { echo -e "${cYel}[sd warn]${cOff} $*" >&2; }
die()   { echo -e "${cRed}[sd err]${cOff} $*" >&2; exit 1; }
need()  { command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"; }

# ===== Banner =====
banner() {
  cat <<'BANNER'
  ____     __  __    ____     _        ___    _____        
 / ___|   |  \/  |  / __ \   | |      |_ _|  |_   _|
 \___ \   | |\/| | | |  | |  | |       | |     | |
  ___) |  | |  | | | |__| |  | |___    | |     | |
 |____/   |_|  |_|  \____/   |_____|  |___|    |_|    _dev

OpenHands + MCP + Claude & Codex Bridge
repo helpers: analyze/index/test/next
send/init/repl • keys/llm • ports/deps • project/init
BANNER
}

# ===== Command Registry =====
declare -A SD_CMDS

sd_register() { 
  # sd_register "cmd" "help" fn_name
  local cmd="$1" help="$2" fn="$3"
  SD_CMDS["$cmd"]="$fn|$help"
}

sd_dispatch() {
  local cmd="${1:-help}"; shift || true
  case "$cmd" in
    help|-h|--help) sd_help ;;
    *)  
      local entry="${SD_CMDS[$cmd]:-}"
      [[ -z "$entry" ]] && die "unknown command: $cmd"
      local fn="${entry%%|*}"
      "$fn" "$@"
    ;;
  esac
}

sd_help() {
  banner
  echo "Usage: sd <command> [...]"; echo; echo "Commands:"
  for k in "${!SD_CMDS[@]}"; do 
    printf "  %-16s %s\n" "$k" "${SD_CMDS[$k]#*|}"
  done | sort
  echo
  echo "Env:"
  echo "  ENV_FILE=${ENV_FILE:-$CONF_DIR/.env}"
  echo "  WORKSPACE=$WORKSPACE"
  echo "  Ports: OH=$OH_PORT SEQ=$SEQ_PORT MEM=$MEM_PORT BRIDGE=$BRIDGE_PORT"
}

# ===== Plugin System =====
load_plugins() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  for p in "$dir"/*/plugin.sh; do
    [[ -f "$p" ]] && source "$p"
  done
}

# ===== Helpers =====
pidfile() { echo "$PID_DIR/$1.pid"; }
is_running() { 
  [[ -f "$(pidfile "$1")" ]] && kill -0 "$(cat "$(pidfile "$1")")" 2>/dev/null
}

require_node18() {
  need node
  local major; major="$(node -p 'process.versions.node.split(".")[0]')" || true
  [[ "${major:-0}" -ge 18 ]] || warn "Node >= 18 empfohlen (gefunden: $(node -v))."
}

# ===== OS/Platform Helpers =====
OS_UNAME="$(uname -s 2>/dev/null || echo Unknown)"

# BSD sed (macOS) needs -i ''
SED_INPLACE=(-i)
if [[ "$OS_UNAME" == "Darwin" ]]; then SED_INPLACE=(-i ''); fi

# realpath fallback
_realpath() {
  if command -v realpath >/dev/null 2>&1; then
    realpath "$1"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$1" <<'PY'
import os,sys; print(os.path.abspath(sys.argv[1]))
PY
  else
    (
      cd "$(dirname -- "$1")" >/dev/null 2>&1 || exit 1
      printf '%s/%s\n' "${PWD}" "$(basename -- "$1")"
    )
  fi
}

# open URL cross-platform
_open_url() {
  local url="$1"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
  elif [[ "$OS_UNAME" == "Darwin" ]] && command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 || true
  elif command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /c start "" "$url" >/dev/null 2>&1 || true
  else
    echo "Open: $url"
  fi
}

# sed escape helper
_escape_sed() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }