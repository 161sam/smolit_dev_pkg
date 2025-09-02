#!/usr/bin/env bash
# lib/bridge.sh - Bridge management and communication
set -Eeuo pipefail
IFS=$'\n\t'

# ===== Bridge Management =====
start_bridge() {
  require_node18
  if _port_in_use "$BRIDGE_PORT"; then
    warn "Bridge-Port $BRIDGE_PORT bereits belegt – überspringe Start."
    return 0
  fi
  [[ -f "$BRIDGE_BIN" ]] || die "bridge.mjs nicht gefunden: $BRIDGE_BIN"
  
  log "Starte Bridge auf Port $BRIDGE_PORT (WORKSPACE=$WORKSPACE)…"
  nohup node "$BRIDGE_BIN" \
    --port "$BRIDGE_PORT" \
    --workspace "$WORKSPACE" \
    --allowed-tools "$SD_ALLOWED_TOOLS" \
    $( [[ -n "$SD_BYPASS_PERMISSIONS" ]] && echo "--dangerously-skip-permissions" ) \
    >>"$LOG_DIR/bridge.log" 2>&1 &
  echo $! >"$(pidfile bridge)"

  # Wait for healthz (max ~5s)
  local ok=0
  for _ in {1..20}; do
    sleep 0.25
    if curl -fsS "http://127.0.0.1:$BRIDGE_PORT/healthz" >/dev/null 2>&1; then 
      ok=1; break
    fi
  done
  
  if [[ "$ok" != "1" ]]; then
    echo "[sd err] Bridge antwortet nicht auf /healthz. Log-Ausschnitt:"
    echo "------------------------------------------"
    tail -n 80 "$LOG_DIR/bridge.log" || echo "(kein bridge.log gefunden)"
    echo "------------------------------------------"
    die "Bridge-Start fehlgeschlagen."
  fi
}

stop_bridge() {
  if is_running bridge; then
    log "Stoppe Bridge (PID $(cat "$(pidfile bridge)") )…"
    kill "$(cat "$(pidfile bridge)")" 2>/dev/null || true
    rm -f "$(pidfile bridge)"
  fi
}

# ===== Bridge Communication =====
send_to_bridge_file() {
  local file="$1"
  [[ -f "$file" ]] || die "Datei nicht gefunden: $file"

  local base="${SD_BRIDGE_ENDPOINT_BASE:-http://127.0.0.1:${BRIDGE_PORT}}"
  local endpoint="${SD_BRIDGE_ENDPOINT:-}"

  local mode="${SD_BRIDGE_PATH_MODE:-auto}"
  local fparam="${SD_BRIDGE_FILE_PARAM:-file}"
  local abs="$(_realpath "$file")"
  local cpath="/workspace${file#"$WORKSPACE"}"

  # Path candidates
  local candidates=()
  case "$mode" in
    container) candidates=("$cpath");;
    local)     candidates=("$abs");;
    auto|*)    candidates=("$abs" "$cpath");;
  esac

  local paths=("/run" "/run-file" "/api/run" "/v1/run" "/execute" "/api/execute")
  local params=("$fparam" $([[ "$fparam" == "file" ]] && echo "path" || echo "file"))

  if [[ -n "$endpoint" ]]; then
    for mp in "${candidates[@]}"; do
      # GET
      local code="$(curl -sS -o /dev/null -w "%{http_code}" --get "$endpoint" --data-urlencode "${fparam}=${mp}" 2>/dev/null || echo 000)"
      [[ "$code" == "200" ]] && { echo "[sd] Bridge OK via GET $endpoint ($fparam=$( [[ "$mp" == "$abs" ]] && echo local || echo container))"; return 0; }
      # POST JSON
      code="$(curl -sS -o /dev/null -w "%{http_code}" -X POST "$endpoint" -H 'Content-Type: application/json' -d "{\"${fparam}\":\"${mp}\"}" 2>/dev/null || echo 000)"
      [[ "$code" == "200" ]] && { echo "[sd] Bridge OK via POST $endpoint ($fparam=$( [[ "$mp" == "$abs" ]] && echo local || echo container))"; return 0; }
    done
  else
    for p in "${paths[@]}"; do
      for prm in "${params[@]}"; do
        for mp in "${candidates[@]}"; do
          # GET
          local code="$(curl -sS -o /dev/null -w "%{http_code}" --get "${base}${p}" --data-urlencode "${prm}=${mp}" 2>/dev/null || echo 000)"
          if [[ "$code" == "200" ]]; then
            echo "[sd] Bridge OK via GET ${p} (${prm}=$( [[ "$mp" == "$abs" ]] && echo local || echo container))"
            return 0
          fi
          # POST JSON
          code="$(curl -sS -o /dev/null -w "%{http_code}" -X POST "${base}${p}" -H 'Content-Type: application/json' -d "{\"${prm}\":\"${mp}\"}" 2>/dev/null || echo 000)"
          if [[ "$code" == "200" ]]; then
            echo "[sd] Bridge OK via POST ${p} (${prm}=$( [[ "$mp" == "$abs" ]] && echo local || echo container))"
            return 0
          fi
        done
      done
    done
  fi

  # Debug output
  local url="${base}/run"
  local body="$(curl -sS --get "$url" --data-urlencode "${fparam}=${cpath}" 2>&1 || true)"
  echo "[sd err] Bridge-Aufruf fehlgeschlagen. Letzte Antwort von $url (mit /workspace):"
  echo "$body" | sed -n '1,20p'
  return 1
}

send_to_bridge_prompt() {
  local prompt="$1"
  [[ -n "${prompt:-}" ]] || die "Leerer Prompt."

  local base="${SD_BRIDGE_ENDPOINT_BASE:-http://127.0.0.1:${BRIDGE_PORT}}"
  local endpoint="${SD_BRIDGE_ENDPOINT:-}"
  local paths=("/run" "/api/run" "/v1/run" "/execute" "/api/execute")

  if [[ -n "$endpoint" ]]; then
    # GET
    local codes="$(curl -sS -o /dev/null -w "%{http_code}" --get "$endpoint" --data-urlencode "prompt=$prompt" 2>/dev/null || echo 000)"
    [[ "$codes" == "200" ]] && return 0
    # POST JSON
    codes="$(curl -sS -o /dev/null -w "%{http_code}" -X POST "$endpoint" -H 'Content-Type: application/json' -d "{\"prompt\":$(printf %s "$prompt" | jq -Rs .)}" 2>/dev/null || echo 000)"
    [[ "$codes" == "200" ]] && return 0
  else
    for p in "${paths[@]}"; do
      # GET
      local url="${base}${p}"
      local codes="$(curl -sS -o /dev/null -w "%{http_code}" --get "$url" --data-urlencode "prompt=$prompt" 2>/dev/null || echo 000)"
      if [[ "$codes" == "200" ]]; then 
        echo "[sd] Bridge OK via GET $p"; return 0
      fi
      # POST JSON
      codes="$(curl -sS -o /dev/null -w "%{http_code}" -X POST "$url" -H 'Content-Type: application/json' -d "{\"prompt\":$(printf %s "$prompt" | jq -Rs .)}" 2>/dev/null || echo 000)"
      if [[ "$codes" == "200" ]]; then 
        echo "[sd] Bridge OK via POST $p"; return 0
      fi
    done
  fi

  local body="$(curl -sS --get "${base}/run" --data-urlencode "prompt=$prompt" 2>&1 || true)"
  echo "[sd err] Bridge-Aufruf fehlgeschlagen. Letzte Antwort:"
  echo "$body" | sed -n '1,20p'
  return 1
}

# ===== Bridge Probe =====
probe_bridge() {
  start_bridge
  sleep 0.3
  local base="${SD_BRIDGE_ENDPOINT_BASE:-http://127.0.0.1:${BRIDGE_PORT}}"
  local f="$WORKSPACE/.openhands/prompts/init_prompt.txt"
  mkdir -p "$(dirname "$f")"
  [[ -f "$f" ]] || echo "PING" > "$f"

  local abs="$(_realpath "$f")"
  local cpath="/workspace${f#"$WORKSPACE"}"
  local paths=("/run" "/run-file" "/api/run" "/v1/run" "/execute" "/api/execute")
  local modes=("local:$abs" "container:$cpath")
  local params=("file" "path")
  local ok=0

  echo "Probing Bridge @ ${base}"
  for p in "${paths[@]}"; do
    for m in "${modes[@]}"; do
      IFS=: read -r mname mp <<<"$m"
      for prm in "${params[@]}"; do
        # GET
        local code="$(curl -sS -o /dev/null -w "%{http_code}" --get "${base}${p}" --data-urlencode "${prm}=${mp}" 2>/dev/null || echo 000)"
        [[ "$code" == "200" ]] && { echo "✓ GET  ${p}  ${prm}=${mname}   (200)"; ok=1; }
        # POST
        code="$(curl -sS -o /dev/null -w "%{http_code}" -X POST "${base}${p}" -H 'Content-Type: application/json' -d "{\"${prm}\":\"${mp}\"}" 2>/dev/null || echo 000)"
        [[ "$code" == "200" ]] && { echo "✓ POST ${p}  ${prm}=${mname}   (200)"; ok=1; }
      done
    done
  done

  if [[ "$ok" == "1" ]]; then
    echo
    echo "Tip: Setze passende Defaults in ~/.config/smolit_dev/.env, z.B.:"
    echo "  SD_BRIDGE_PATH_MODE=container"
    echo "  SD_BRIDGE_FILE_PARAM=file"
    echo "  SD_BRIDGE_ENDPOINT_BASE=${base}"
  else
    echo
    echo "Keine Kombination lieferte 200. Prüfe die Bridge-Routen manuell oder setze SD_BRIDGE_ENDPOINT explizit."
  fi
}

# Register commands
sd_register "probe-bridge" "Bridge Routen-/Methoden-Autodetect" probe_bridge