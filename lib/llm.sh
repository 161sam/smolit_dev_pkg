#!/usr/bin/env bash
# lib/llm.sh - LLM management functions
set -Eeuo pipefail
IFS=$'\n\t'

# Idempotent sourcing guard
if [[ "${SD_LLM_SH_LOADED:-0}" = "1" ]]; then
  return 0
fi
SD_LLM_SH_LOADED=1

# ===== Keys & LLM Management =====
keys_init() {
  mkdir -p "$(dirname "$ENV_FILE")"
  touch "$ENV_FILE"
  echo "API-Keys/URLs setzen (leer lassen zum Überspringen):"
  read -r -p "ANTHROPIC_API_KEY: " k1 || true
  read -r -p "LM_BASE_URL [${LM_BASE_URL}]: " k2 || true
  [[ -n "$k1" ]] && write_env_kv "ANTHROPIC_API_KEY" "$k1"
  [[ -n "$k2" ]] && write_env_kv "LM_BASE_URL" "$k2"
  echo "Gespeichert in: $ENV_FILE"
}

llm_list() {
  local url="$LM_BASE_URL/models"
  echo "Modelle von ${url}:"
  if command -v jq >/dev/null 2>&1; then
    curl -fsS "$url" | jq -r '
      (if type=="object" and has("data") then .data else . end)
      | (..|objects|select(has("id"))|.id)' | sort -u
  else
    curl -fsS "$url" || true
  fi
}

llm_use() {
  local id="${1:-}"
  [[ -n "$id" ]] || die "Usage: sd llm use <model-id>"
  write_env_kv "SD_LLM_MODEL" "$id"
  echo "SD_LLM_MODEL=$id gesetzt (in $ENV_FILE)."
}

# Register commands
sd_register "keys:init" "API-Keys setzen (optional)" keys_init
sd_register "llm:list" "Modelle aus LM Studio anzeigen" llm_list
sd_register "llm:use" "bevorzugtes Modell merken (SD_LLM_MODEL)" llm_use
