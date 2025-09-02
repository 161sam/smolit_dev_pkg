#!/usr/bin/env bash
# migrate-to-modular.sh - Migration zu modularer sd CLI Architektur
set -Eeuo pipefail

# Colors
cGreen=$'\e[32m'; cYel=$'\e[33m'; cBlue=$'\e[34m'; cRed=$'\e[31m'; cOff=$'\e[0m'
info() { echo -e "${cBlue}[info]${cOff} $*"; }
warn() { echo -e "${cYel}[warn]${cOff} $*"; }
ok() { echo -e "${cGreen}[ok]${cOff} $*"; }
err() { echo -e "${cRed}[error]${cOff} $*" >&2; }

echo "🧩 SD CLI Migration zu Modularer Architektur v0.2.0"
echo "=================================================="
echo

# ===== Sicherheitscheck =====
if [[ ! -f "bin/sd" ]]; then
  err "bin/sd nicht gefunden. Bist du im richtigen Verzeichnis (smolit_dev_pkg)?"
  exit 1
fi

if [[ ! -f "package.json" ]]; then
  err "package.json nicht gefunden. Bist du im richtigen Verzeichnis?"
  exit 1
fi

info "Aktuelles Verzeichnis: $(pwd)"
info "Gefunden: bin/sd ($(wc -l < bin/sd) Zeilen)"

# ===== Backup bestehender Dateien =====
echo
info "📦 Erstelle Backups..."

# Backup bin/sd
if [[ ! -f "bin/sd.bak.pre-modular" ]]; then
  cp bin/sd bin/sd.bak.pre-modular
  ok "bin/sd → bin/sd.bak.pre-modular"
else
  warn "bin/sd.bak.pre-modular existiert bereits"
fi

# Backup package.json
if [[ ! -f "package.json.bak.pre-modular" ]]; then
  cp package.json package.json.bak.pre-modular  
  ok "package.json → package.json.bak.pre-modular"
else
  warn "package.json.bak.pre-modular existiert bereits"
fi

# Backup tests/run-tests.mjs
if [[ -f "tests/run-tests.mjs" ]] && [[ ! -f "tests/run-tests.mjs.bak.pre-modular" ]]; then
  cp tests/run-tests.mjs tests/run-tests.mjs.bak.pre-modular
  ok "tests/run-tests.mjs → tests/run-tests.mjs.bak.pre-modular"
fi

# ===== Verzeichnisstruktur erstellen =====
echo
info "📁 Erstelle neue Verzeichnisstruktur..."

directories=(
  "lib"
  "plugins"
  "plugins/example" 
  "src"
  "src/cli"
  "src/commands"
  "src/commands/bridge"
  "src/plugins"
  "src/plugins/example"
  "templates/microagent"
  "templates/prompt"
)

for dir in "${directories[@]}"; do
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    ok "Erstellt: $dir/"
  else
    warn "Existiert bereits: $dir/"
  fi
done

# ===== Module-Platzhalter erstellen (lib/) =====
echo
info "🔧 Erstelle Modul-Platzhalter..."

modules=(
  "core.sh:Command-Registry, Logging, Plugin-System"
  "config.sh:ENV-Layering, XDG-Pfade, Template-Rendering"
  "ports.sh:Port-Checking-Utilities" 
  "docker.sh:OpenHands Container Management"
  "bridge.sh:Bridge Management & HTTP-Kommunikation"
  "oh.sh:Health-Checks & Stack-Commands"
  "prompts.sh:Template-Rendering & Prompt-Commands"
  "mcp.sh:MCP & Projekt-Setup"
  "llm.sh:LLM-Management & API-Keys"
  "repl.sh:REPL & Send-Funktionen"
)

for module in "${modules[@]}"; do
  IFS=':' read -r filename description <<< "$module"
  filepath="lib/$filename"
  
  if [[ ! -f "$filepath" ]]; then
    cat > "$filepath" <<EOF
#!/usr/bin/env bash
# lib/$filename - $description
set -Eeuo pipefail
IFS=\$'\\n\\t'

# TODO: Implementierung aus bin/sd extrahieren
# Verantwortlich für: $description

# Beispiel Command-Registrierung:
# example_command() {
#   echo "Hello from $filename"
# }
# sd_register "example" "Beispiel-Kommando" example_command

EOF
    chmod +x "$filepath"
    ok "Erstellt: $filepath"
  else
    warn "Existiert bereits: $filepath"
  fi
done

# ===== Plugin-Platzhalter erstellen =====
echo
info "🧩 Erstelle Plugin-Platzhalter..."

# Bash Plugin Beispiel
plugin_bash="plugins/example/plugin.sh"
if [[ ! -f "$plugin_bash" ]]; then
  cat > "$plugin_bash" <<'EOF'
#!/usr/bin/env bash
# plugins/example/plugin.sh - Demo Bash-Plugin
set -Eeuo pipefail
IFS=$'\n\t'

# TODO: Plugin-Funktionen implementieren

example_echo() { 
  echo "Hello from plugin: $*"; 
}

example_workspace() {
  echo "Current workspace: $WORKSPACE"
  echo "Available commands: ${!SD_CMDS[*]}" | tr ' ' '\n' | sort
}

# Plugin-Commands registrieren
sd_register "example:echo" "Demo-Plugin sagt hallo" example_echo
sd_register "example:workspace" "Zeigt Workspace und verfügbare Kommandos" example_workspace
EOF
  chmod +x "$plugin_bash"
  ok "Erstellt: $plugin_bash"
else
  warn "Existiert bereits: $plugin_bash"
fi

# ===== Node CLI Platzhalter (src/) =====
echo
info "⚡ Erstelle Node CLI Platzhalter..."

node_files=(
  "src/cli/index.mjs:Node CLI Entry Point"
  "src/cli/loader.mjs:Command & Plugin Loader"
  "src/commands/bridge/probe.mjs:Bridge Probe Command"
  "src/plugins/example/index.mjs:Beispiel JS-Plugin"
)

for file_desc in "${node_files[@]}"; do
  IFS=':' read -r filepath description <<< "$file_desc"
  
  if [[ ! -f "$filepath" ]]; then
    cat > "$filepath" <<EOF
#!/usr/bin/env node
// $filepath - $description
// TODO: Implementierung hinzufügen

console.log("TODO: $description");
console.log("Datei: $filepath");

// Phase 2: Node CLI Implementation
export default {};
EOF
    chmod +x "$filepath" 2>/dev/null || true
    ok "Erstellt: $filepath"
  else
    warn "Existiert bereits: $filepath"
  fi
done

# ===== Template-Platzhalter =====
echo
info "📝 Erstelle Template-Platzhalter..."

# Prüfe bestehende Templates und erstelle fehlende
existing_templates=()
if [[ -d "templates" ]]; then
  while IFS= read -r -d '' file; do
    existing_templates+=("$(basename "$file")")
  done < <(find templates -name "*.md" -print0 2>/dev/null || true)
fi

needed_templates=(
  "normalize-user-input.md:Nutzer-Input normalisieren"
  "send-to-claude.md:Init-Prompt für Claude"
  "talk-to-claude.md:Follow-up-Prompt für Claude" 
  "claude-to-codex.md:Codex-Brief von Claude"
  "guardrails.md:Sicherheits-/Policy-Regeln"
  "analyze.md:Repository-Analyse"
  "index.md:Repo-Indexierung"
  "test.md:Test-Analyse"
  "next.md:Nächste Schritte"
)

for template_desc in "${needed_templates[@]}"; do
  IFS=':' read -r filename description <<< "$template_desc"
  
  # Prüfe ob Template bereits existiert (auch in Unterverzeichnissen)
  if printf '%s\0' "${existing_templates[@]}" | grep -Fxqz -- "$filename"; then
    warn "Template existiert bereits: $filename"
    continue
  fi
  
  filepath="templates/$filename"
  if [[ ! -f "$filepath" ]]; then
    cat > "$filepath" <<EOF
# $description

## Zweck
TODO: $description

## Context
- Projekt: {{PROJECT}}
- Workspace: {{WORKSPACE}}
- Datum: {{DATE_ISO}}

## TODO
Implementierung hinzufügen für: $description

## Platzhalter
- {{PROJECT}} wird durch Projektname ersetzt
- {{WORKSPACE}} wird durch WORKSPACE-Pfad ersetzt
- {{DATE_ISO}} wird durch aktuelles Datum ersetzt
- {{LM_BASE_URL}} wird durch LM_BASE_URL ersetzt
EOF
    ok "Erstellt: $filepath"
  else
    warn "Existiert bereits: $filepath"
  fi
done

# ===== Dokumentations-Platzhalter =====
echo
info "📖 Erstelle Dokumentations-Platzhalter..."

docs=(
  "RELEASE_NOTES.md:Release Notes v0.2.0"
  "MIGRATION.md:Migration Guide"
  "TEST_GUIDE.md:Test & Validation Guide"
)

for doc_desc in "${docs[@]}"; do
  IFS=':' read -r filename description <<< "$doc_desc"
  
  if [[ ! -f "$filename" ]]; then
    cat > "$filename" <<EOF
# $description

## TODO
Dokumentation vervollständigen für: $description

## Status
- [ ] Inhalt hinzufügen
- [ ] Beispiele ergänzen  
- [ ] Links überprüfen
- [ ] Format validieren

## Version
v0.2.0 - Modular Architecture
EOF
    ok "Erstellt: $filename"
  else
    warn "Existiert bereits: $filename"
  fi
done

# ===== Neues bin/sd Platzhalter =====
echo
info "🔄 Erstelle neues bin/sd (Dispatcher)..."

new_sd="bin/sd.new.modular"
if [[ ! -f "$new_sd" ]]; then
  cat > "$new_sd" <<'EOF'
#!/usr/bin/env bash
# ==============================================================================
#  sd  —  smolit_dev CLI (modular)  
#  One-command Dev-Stack: OpenHands (Docker) + MCP (SSE) + Claude & Codex Bridge
#  Requirements: bash, docker, node>=18, curl (jq optional)
#  Cross-platform: Linux, macOS; Windows via Node-Launcher + Git Bash
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# ===== Cleanup & Paths =====
cleanup() { :; }
trap cleanup EXIT

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SELF_DIR/.." && pwd)"

# ===== Load Core Modules =====
source "$ROOT_DIR/lib/core.sh"
source "$ROOT_DIR/lib/config.sh"

# ===== Load All Other Modules =====
for f in "$ROOT_DIR/lib/"*.sh; do
  [[ "$f" =~ /(core|config)\.sh$ ]] || source "$f"
done

# ===== Load Plugins =====
load_plugins "$CONF_DIR/plugins"
load_plugins "$WORKSPACE/.sd/plugins"

# ===== Dispatch =====
sd_dispatch "$@"
EOF
  chmod +x "$new_sd"
  ok "Erstellt: $new_sd (wird später nach bin/sd verschoben)"
else
  warn "Existiert bereits: $new_sd"
fi

# ===== Setup-Script =====
setup_script="setup-modular.sh"
if [[ ! -f "$setup_script" ]]; then
  cat > "$setup_script" <<'EOF'
#!/usr/bin/env bash
# setup-modular.sh - Finalisierung der modularen Migration
set -Eeuo pipefail

echo "🔧 Finalisiere modulare SD CLI..."

# 1. Neues bin/sd aktivieren
if [[ -f "bin/sd.new.modular" ]]; then
  mv bin/sd.new.modular bin/sd
  chmod +x bin/sd
  echo "✓ Neues modulares bin/sd aktiviert"
fi

# 2. Tests ausführen
echo "🧪 Führe Tests aus..."
if npm test; then
  echo "✓ Alle Tests erfolgreich"
else
  echo "✗ Tests fehlgeschlagen - prüfe Implementierung"
fi

# 3. Plugin-Test
echo "🧩 Teste Plugin-System..."
if ./bin/sd example:echo "test" 2>/dev/null | grep -q "Hello"; then
  echo "✓ Plugin-System funktional"
else
  echo "ℹ Plugin-System noch nicht vollständig implementiert"
fi

echo "🎉 Migration abgeschlossen!"
echo "Nutze: ./bin/sd --help"
EOF
  chmod +x "$setup_script"
  ok "Erstellt: $setup_script"
fi

# ===== Zusammenfassung =====
echo
echo "🎉 Migration-Setup abgeschlossen!"
echo "================================"
echo
echo "📂 Erstellt:"
echo "  ├── lib/*.sh (10 Module-Platzhalter)"
echo "  ├── plugins/example/plugin.sh"
echo "  ├── src/ (Node CLI Skeleton)"
echo "  ├── templates/*.md (Template-Platzhalter)"
echo "  ├── *.md (Dokumentations-Platzhalter)"
echo "  ├── bin/sd.new.modular (neuer Dispatcher)"
echo "  └── setup-modular.sh (Finalisierungs-Script)"
echo
echo "💾 Backups:"
echo "  ├── bin/sd.bak.pre-modular"
echo "  ├── package.json.bak.pre-modular"
echo "  └── tests/run-tests.mjs.bak.pre-modular"
echo
echo "🔄 Nächste Schritte:"
echo "  1. Kopiere Inhalte aus Artefakten in die Platzhalter-Dateien"
echo "  2. Aktualisiere package.json (Version, files, scripts)"
echo "  3. Führe ./setup-modular.sh aus"
echo "  4. Teste: ./bin/sd --help"
echo "  5. Git Workflow: branch → commit → push → PR → release"
echo
echo "📋 TODO-Liste:"
echo "  ☐ lib/core.sh implementieren (Command-Registry)"
echo "  ☐ lib/config.sh implementieren (ENV-Layering)" 
echo "  ☐ lib/docker.sh implementieren (Container-Management)"
echo "  ☐ lib/bridge.sh implementieren (HTTP-Client)"
echo "  ☐ lib/prompts.sh implementieren (Template-System)"
echo "  ☐ Restliche lib/*.sh Module implementieren"
echo "  ☐ Templates mit Inhalt füllen"
echo "  ☐ Dokumentation vervollständigen"
echo "  ☐ package.json aktualisieren"
echo "  ☐ Tests erweitern"

# File count
lib_count=$(find lib -name "*.sh" 2>/dev/null | wc -l)
template_count=$(find templates -name "*.md" 2>/dev/null | wc -l)
doc_count=$(find . -maxdepth 1 -name "*.md" ! -name "README.md" 2>/dev/null | wc -l)

echo
ok "Statistik: $lib_count Module, $template_count Templates, $doc_count Docs erstellt"
echo "Status: Bereit für Implementierung! 🚀"
