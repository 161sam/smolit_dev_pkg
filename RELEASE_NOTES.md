# Release Notes v0.2.0 - Modular Architecture

## 🚀 Major Refactoring: Monolith → Modular

### ✨ New Features
- **Plugin-System**: Bash und JavaScript Plugins
- **Modular Architecture**: Code aufgeteilt in `lib/*.sh` Module  
- **Command Registry**: Dynamische Kommando-Registrierung
- **Node CLI Skeleton**: Vorbereitung für Phase 2

### 🔧 Internal Changes
- `bin/sd`: 560+ Zeilen → 30 Zeilen (dünner Dispatcher)
- Neue Module: `core`, `config`, `ports`, `docker`, `bridge`, `oh`, `prompts`, `mcp`, `llm`, `repl`
- Plugin-Discovery: `~/.config/smolit_dev/plugins/` + `$WORKSPACE/.sd/plugins/`

### 💯 Backward Compatibility
- **Alle** bestehenden `sd`-Kommandos funktionieren identisch
- Keine Breaking Changes für Endnutzer
- Bestehende ENV-Variablen und Konfiguration unverändert

### 🧪 Testing
- Erweiterte Smoke-Tests für Plugin-System
- Syntax-Checks für alle Module: `npm run test:modules`
- Shell-Linting: `npm run lint:shell`

### 📦 Packaging
- Neue `files`: `lib/`, `plugins/`, `src/`
- Version bump: v0.1.0 → v0.2.0
- Zusätzliche Keywords: `modular`, `plugins`

## Migration Path

1. **Sofort**: Alle bestehenden Kommandos funktionieren
2. **Plugins**: Erstelle eigene in `~/.config/smolit_dev/plugins/`
3. **Node CLI**: Optional via `node src/cli/index.mjs` (experimentell)

## Breaking Changes
- **Keine** für normale Nutzung
- **Entwickler**: Code-Organisation geändert (falls jemand `bin/sd` direkt modifiziert hatte)

## Performance
- **Startup**: Marginaler Overhead durch Module-Loading (~10ms)
- **Runtime**: Identisch zu vorher
- **Memory**: Etwas weniger, da Code modularer geladen wird

---

**Upgrade:** `npm update -g smolit-dev`