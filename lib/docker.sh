#!/usr/bin/env bash
# lib/docker.sh - Docker container management
set -Eeuo pipefail
IFS=$'\n\t'

# ===== OpenHands Container Management =====
start_openhands() {
  need docker
  if docker ps --format '{{.Names}}' | grep -q "^${OH_NAME}\$"; then
    warn "OpenHands Container '$OH_NAME' läuft bereits."
    return 0
  fi

  # Detect new OpenHands GUI vs legacy
  if [[ "$OH_IMAGE" == docker.all-hands.dev/all-hands-ai/openhands:* ]] || [[ "$OH_IMAGE" == ghcr.io/all-hands-ai/openhands:* ]]; then
    : "${OH_PORT:=3000}"
    : "${SANDBOX_RUNTIME_CONTAINER_IMAGE:=docker.all-hands.dev/all-hands-ai/runtime:0.54-nikolaik}"

    log "Starte OpenHands GUI ($OH_IMAGE) → Port $OH_PORT …"
    docker run -d --rm \
      --name "$OH_NAME" \
      --add-host host.docker.internal:host-gateway \
      -p "$OH_PORT:3000" \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "$HOME/.openhands:/.openhands" \
      -e SANDBOX_RUNTIME_CONTAINER_IMAGE="$SANDBOX_RUNTIME_CONTAINER_IMAGE" \
      "$OH_IMAGE" \
      >/dev/null || die "Docker-Start fehlgeschlagen."

    # Health wait
    for _ in {1..40}; do
      sleep 0.25
      curl -fsS "http://127.0.0.1:$OH_PORT" >/dev/null 2>&1 && break || true
    done
    return 0
  fi

  # Legacy mode for old images
  if ! curl -fsS -m 1 "$LM_BASE_URL/models" >/dev/null 2>&1; then
    warn "LM_BASE_URL ($LM_BASE_URL) konnte nicht geprüft werden – fahre fort."
  fi
  
  log "Starte OpenHands (legacy, $OH_IMAGE) auf Ports GUI:$OH_PORT SEQ:$SEQ_PORT MEM:$MEM_PORT …"
  docker run -d --rm \
    --name "$OH_NAME" \
    --add-host host.docker.internal:host-gateway \
    -p "$OH_PORT:3311" -p "$SEQ_PORT:8811" -p "$MEM_PORT:8812" \
    -e LM_BASE_URL="$LM_BASE_URL" \
    -v "$WORKSPACE:/workspace" \
    "$OH_IMAGE" \
    >/dev/null || die "Docker-Start fehlgeschlagen (legacy)."

  for _ in {1..40}; do
    sleep 0.25
    curl -fsS "http://127.0.0.1:$OH_PORT" >/dev/null 2>&1 && break || true
  done
}

stop_openhands() {
  if docker ps --format '{{.Names}}' | grep -q "^${OH_NAME}\$"; then
    log "Stoppe OpenHands Container '$OH_NAME' …"
    docker rm -f "$OH_NAME" >/dev/null || true
  fi
}

# ===== Helper Functions =====
open_browser() {
  local url="http://127.0.0.1:$OH_PORT"
  _open_url "$url"
  echo "GUI: $url"
}

tail_logs() {
  echo "Logs in: $LOG_DIR"
  echo "Docker logs ($OH_NAME) und bridge.log folgen (Ctrl-C beendet)…"
  { docker logs -f "$OH_NAME" 2>&1 & echo $! >"$(pidfile dockerlogs)"; } || true
  tail -n 200 -F "$LOG_DIR/bridge.log" || true
  kill "$(cat "$(pidfile dockerlogs)" 2>/dev/null)" 2>/dev/null || true
  rm -f "$(pidfile dockerlogs)" || true
}

# ===== Dependencies Check =====
deps_doctor() {
  echo "Dependencies:"
  for b in node npm docker npx curl; do
    if command -v "$b" >/dev/null 2>&1; then
      echo "  ✓ $b: $(command -v "$b")"
    else
      echo "  ✗ $b fehlt"
    fi
  done
  if ! groups | grep -q '\bdocker\b'; then
    echo "  ${cDim}Hinweis:${cOff} Benutzer nicht in 'docker' Gruppe – ggf. 'sudo usermod -aG docker $USER' und neu anmelden."
  fi
}

deps_install() {
  echo "[sd] Lokale CLI-Dependencies werden über dieses Paket bereitgestellt."
  echo "[sd] Optionale globale CLI:"
  echo "     npm i -g @anthropic-ai/claude-code"
}

deps_install_global() {
  npm i -g @anthropic-ai/claude-code
}

# Register commands
sd_register "deps:doctor" "Dependency-Check" deps_doctor
sd_register "deps:install" "Setup-Hinweise anzeigen" deps_install
sd_register "deps:install-global" "Globale CLIs installieren" deps_install_global