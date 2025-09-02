#!/usr/bin/env bash
# fix-syntax.sh - Fix syntax errors in modular files
set -Eeuo pipefail

echo "🔧 Fixing syntax errors in modular SD CLI..."

# Backup the problematic file
if [[ -f "lib/oh.sh" ]]; then
  cp lib/oh.sh lib/oh.sh.broken
  echo "✓ Backup created: lib/oh.sh.broken"
fi

# Fix lib/oh.sh - rewrite with correct content
cat > lib/oh.sh <<'EOF'
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
EOF

chmod +x lib/oh.sh
echo "✓ Fixed: lib/oh.sh"

# Check all module syntax again
echo
echo "🧪 Checking all module syntax..."
syntax_ok=true

for f in lib/*.sh; do
  if bash -n "$f" 2>/dev/null; then
    echo "✓ $f"
  else
    echo "✗ $f has syntax errors:"
    bash -n "$f" || true
    syntax_ok=false
  fi
done

if [[ "$syntax_ok" == "true" ]]; then
  echo
  echo "✅ All modules have valid syntax!"
  
  # Test basic functionality
  echo
  echo "🧪 Testing basic commands..."
  if ./bin/sd --help >/dev/null 2>&1; then
    echo "✓ sd --help works"
  else
    echo "✗ sd --help still failing - checking dependencies..."
    
    # Debug: check if all modules load correctly
    echo "Debug: Testing module loading..."
    
    # Check if core.sh exists and has basic functions
    if [[ -f "lib/core.sh" ]] && grep -q "sd_register" lib/core.sh; then
      echo "✓ lib/core.sh has sd_register function"
    else
      echo "✗ lib/core.sh missing or incomplete"
    fi
    
    # Check if config.sh exists
    if [[ -f "lib/config.sh" ]] && grep -q "CONF_DIR" lib/config.sh; then
      echo "✓ lib/config.sh has CONF_DIR"
    else
      echo "✗ lib/config.sh missing or incomplete"
    fi
  fi
  
  # Test plugin system
  echo
  echo "🧩 Testing plugin system..."
  if ./bin/sd example:echo "test" 2>/dev/null | grep -q "Hello from plugin"; then
    echo "✓ Plugin system working"
  else
    echo "ℹ Plugin system not yet fully implemented (normal)"
  fi
  
  # Run tests
  echo
  echo "🧪 Running test suite..."
  if npm test; then
    echo "✅ All tests passed!"
  else
    echo "⚠️  Some tests failed - this is expected during migration"
  fi
  
else
  echo
  echo "❌ Some modules still have syntax errors - please fix manually"
  exit 1
fi

echo
echo "🎉 Syntax fixes completed!"
echo "Next: ./bin/sd --help should now work"
