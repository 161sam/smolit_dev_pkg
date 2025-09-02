# Test Guide - Modular SD CLI

## Quick Tests

```bash
# 1. Syntax check aller Module
bash -n lib/*.sh && echo "✓ Alle Module OK"

# 2. Basis-Funktionalität
./bin/sd --help

# 3. Plugin-System  
./bin/sd example:echo "test"
./bin/sd example:workspace

# 4. Core Commands (ohne Docker/Bridge)
./bin/sd deps doctor
./bin/sd ports doctor

# 5. Vollständige Tests
npm test
```

## Erweiterte Tests

```bash
# Template-System
./bin/sd init              # Erstellt .claude/settings.json
ls -la ~/.config/smolit_dev/.env  # ENV-File Check

# Mit Docker (falls verfügbar)
./bin/sd up                # Startet Stack
./bin/sd status            # Health-Check
./bin/sd probe-bridge      # Bridge-Routen testen
./bin/sd stop              # Clean shutdown

# Node CLI (experimentell)
node src/cli/index.mjs --help
node src/cli/index.mjs bridge:probe
```

## Expected Outputs

### sd --help
```
  ____     __  __    ____     _        ___    _____        
 / ___|   |  \/  |  / __ \   | |      |_ _|  |_   _|
 \___ \   | |\/| | | |  | |  | |       | |     | |
  ___) |  | |  | | | |__| |  | |___    | |     | |
 |____/   |_|  |_|  \____/   |_____|  |___|    |_|    _dev

Usage: sd <command> [...]

Commands:
  analyze          Repo-Analyse starten
  c                Kurzform für 'sd send c …'
  claude-fu        Follow-up (kleine Schritte) an Claude senden
  claude-init      Supervisor-Init-Prompt an Claude senden
  ...
```

### sd example:echo test
```
Hello from plugin: test
```

## Regressionstests

Diese Kommandos sollten **identisch** zu vorher funktionieren:

```bash
./bin/sd up
./bin/sd start  
./bin/sd stop
./bin/sd status
./bin/sd logs
./bin/sd deps doctor
./bin/sd ports doctor
./bin/sd project init
./bin/sd init
./bin/sd mcp status
./bin/sd analyze
./bin/sd index
./bin/sd test
./bin/sd next
./bin/sd norm
./bin/sd claude-init
./bin/sd codex-brief
./bin/sd claude-fu
./bin/sd guardrails
./bin/sd probe-bridge
./bin/sd keys init
./bin/sd llm list
./bin/sd llm use model-id
./bin/sd start-repl
./bin/sd send init "text"
./bin/sd send c "text" 
./bin/sd c "text"
```

## Fehlerbehebung

### Module nicht gefunden
```bash
# Debug: zeige Pfade
SELF_DIR="$(cd "$(dirname "bin/sd")" && pwd)"
ROOT_DIR="$(cd "$SELF_DIR/.." && pwd)" 
echo "ROOT_DIR: $ROOT_DIR"
ls -la "$ROOT_DIR/lib/"
```

### Plugin-Probleme
```bash
# Plugin-Pfade prüfen
echo "CONF_DIR: $CONF_DIR"
echo "WORKSPACE: $WORKSPACE"
ls -la ~/.config/smolit_dev/plugins/ 2>/dev/null || echo "Keine User-Plugins"
ls -la ./.sd/plugins/ 2>/dev/null || echo "Keine Projekt-Plugins"
```

### Kommando nicht registriert
```bash
# Debug: alle registrierten Kommandos
grep -r "sd_register" lib/ plugins/ 2>/dev/null
```