# smolit_dev_pkg (sd) - Modular Dev-Stack CLI

**sd** ist ein schlanker, modularer Dev-Orchestrator:  
👉 Startet **OpenHands** (Docker), verbindet **MCP (Sequential Thinking + Memory)** und bietet eine **Claude-Bridge** per HTTP.  
🧩 **Plugin-System** für Bash & JavaScript, modulare Architektur mit klaren Verantwortlichkeiten.  
⚡ **Erweiterbares CLI** mit Command-Registry und automatischer Plugin-Discovery.

---

## 🚀 Quickstart

```bash
npm install -g smolit-dev
sd deps doctor
sd up          # Startet OpenHands (Docker) + Bridge
sd status      # Health-Check (GUI, MCP, Bridge)
```

GUI: [http://127.0.0.1:3311](http://127.0.0.1:3311)  
Bridge: [http://127.0.0.1:8815/healthz](http://127.0.0.1:8815/healthz)

---

## 🧩 Modular Architecture (v0.2.0)

### Struktur
```
bin/sd              # Dünner Dispatcher (30 Zeilen)
lib/                # Thematische Module
├── core.sh         # Command-Registry, Plugin-System
├── config.sh       # ENV-Layering, XDG-Pfade
├── docker.sh       # OpenHands Container-Management
├── bridge.sh       # Bridge-Kommunikation
├── prompts.sh      # Template-Rendering
└── ...            # ports, oh, mcp, llm, repl
plugins/            # Plugin-Discovery
├── example/plugin.sh
└── your-plugin/
src/                # Node CLI (Phase 2, optional)
templates/          # Microagent & Prompt Templates
```

### Plugin-System

**Bash-Plugins** (automatisch geladen):
```bash
# ~/.config/smolit_dev/plugins/my-tool/plugin.sh
my_custom_analyze() { 
  echo "Analyzing project: $WORKSPACE"
  # Your custom logic here
}
sd_register "analyze:custom" "Custom project analysis" my_custom_analyze
```

**JavaScript-Plugins** (experimentell):
```javascript
// ~/.config/smolit_dev/plugins/my-tool/index.mjs  
export function register(registerFn, env) {
  registerFn("my:js-cmd", async (args, env) => {
    console.log("JS Plugin with args:", args);
  }, "Custom JS command");
}
```

**Plugin-Pfade:**
- `~/.config/smolit_dev/plugins/*/plugin.sh` (User)
- `$WORKSPACE/.sd/plugins/*/plugin.sh` (Projekt)

---

## ⚙️ Installation & Setup

### 1. Global Installation

```bash
# NPM Registry
npm i -g smolit-dev (demnächst verfügbar)

# GitHub (Latest)
npm i -g github:161sam/smolit_dev_pkg

# Setup
sd keys init
```

### 2. Dependencies

**Erforderlich:**
- Node.js >= 18
- Docker (für OpenHands)
- Bash (Linux/macOS) oder Git Bash (Windows)

**Optional:**
```bash
sd deps install-global    # @anthropic-ai/claude-code etc.
```

### 3. Ports

- GUI: `3311` (OpenHands)
- MCP Sequential: `8811` 
- MCP Memory: `8812`
- sd-Bridge: `8815`

---

## 🔄 Die sd-Pipeline

Die `sd`-Pipeline verbindet Eingaben, Analyse und KI-Tools:

1. **User Input (unstrukturiert)**
   * *Einfacher Text oder Datei-Inhalt.*
2. **OpenHands (strukturierend)**
   * Läuft in Docker
   * Erkennt Intentionen und strukturiert unklare Eingaben
   * Baut daraus einen validierten Prompt
3. **Claude als Supervisor**
   * Empfängt den strukturierten Prompt von OpenHands
   * Agiert als „Supervisor" und orchestriert die Arbeit
   * Entscheidet, welche Tools/Aktionen erforderlich sind
4. **Codex als Worker**
   * Claude beauftragt Codex (oder ein anderes Modell) mit konkreten Aufgaben
   * Codex führt Code-Analysen, Patch-Erstellung und Refactorings durch
   * Ergebnisse werden zurück in den Pipeline-Kontext gespielt
5. **Memory (MCP)**
   * Erkenntnisse und Ergebnisse werden ins MCP Memory geschrieben
   * Bleiben für spätere Iterationen abrufbar

Ergebnis: **Von unstrukturiertem Userinput → strukturierter Prompt → konkrete Patches & Next Steps.**

---

## 🖥️ CLI Commands

### Stack Management
```bash
sd up              # OpenHands + Bridge starten, GUI öffnen
sd start           # wie 'up', ohne GUI-Open
sd stop            # Container & Bridge stoppen
sd status          # Health-Check
sd logs            # zeigt Log-Verzeichnis
sd logs -f         # folgt Bridge + Docker logs

sd deps doctor     # prüft Dependencies
sd ports doctor    # Port-Kollisionen prüfen
```

### Project Setup
```bash
sd project init    # .claude/settings.json für MCP erzeugen
sd init            # Vollständiges Projekt-Setup
sd mcp status      # MCP-Status prüfen
```

### AI Workflow
```bash
sd analyze         # Repo-Analyse starten
sd index           # aktuelles Repo indexieren (Knowledge-Map)
sd test            # Tests laufen lassen + Patches
sd next            # nächste Schritte erzeugen

# Microagent Templates
sd norm            # Nutzer-Text normalisieren
sd claude-init     # Supervisor-Init-Prompt an Claude
sd codex-brief     # Übergabe-Briefing an Codex
sd claude-fu       # Follow-up (kleine Schritte) 
sd guardrails      # Guardrails/Policy
```

### Interactive & Send
```bash
sd keys init       # API-Keys setzen
sd llm list        # Modelle aus LM Studio anzeigen
sd llm use <id>    # bevorzugtes Modell merken

sd start-repl      # interaktive Session
sd send init "..."  # Initial-/Ziel-Prompt senden
sd send c "..."     # Änderungs-/Follow-up-Prompt
sd c "..."          # Kurzform für 'sd send c ...'
```

### Development & Plugins  
```bash
sd example:echo test        # Test Plugin-System
sd probe-bridge             # Bridge Routen-Detection
bash -n lib/*.sh            # Module syntax check
node src/cli/index.mjs help # Node CLI (experimentell)
```

---

## 🔒 Sicherheit

* **Standardmäßig KEIN** `--dangerously-skip-permissions`.
* Optional via `SD_BYPASS_PERMISSIONS=1` aktivierbar.
* Bridge erlaubt nur definierte Tools:

  ```bash
  SD_ALLOWED_TOOLS="sequential-thinking,memory-shared,memory,codex-bridge"
  ```

---

## 🧩 Integration

### Flowise

* Custom Tool Node: `sdBridge` (→ `http://127.0.0.1:8815/run?prompt=…`)
* Healthcheck Node für Bridge
* Buttons für `sd index/test/next`

### n8n

* Webhook → Bridge Proxy (beliebige Prompts/Dateien)
* Cron-Healthcheck → Memory speichern
* GitHub Push → Repo-Analyse
* Buttons für `sd index`, `sd test`, `sd next`

---

## 📂 Projekt-Struktur

```
smolit_dev_pkg/
├─ bin/
│  ├─ sd                 # Modular CLI Dispatcher
│  ├─ sd-launch.cjs      # Cross-platform Launcher
│  ├─ bridge.mjs         # HTTP Bridge (Claude/MCP)
│  └─ postinstall.mjs    # Idempotentes Setup
├─ lib/                  # Bash-Module
│  ├─ core.sh            # Command-Registry & Plugin-System
│  ├─ config.sh          # ENV-Layering & Template-Rendering
│  ├─ docker.sh          # OpenHands Container Management
│  ├─ bridge.sh          # Bridge-Kommunikation
│  ├─ prompts.sh         # Microagent-Templates
│  └─ ...               # ports, oh, mcp, llm, repl
├─ plugins/              # Plugin-Discovery
│  └─ example/plugin.sh  # Demo Bash-Plugin
├─ src/                  # Node-CLI (Phase 2, optional)
│  ├─ cli/index.mjs      # Entry Point
│  ├─ commands/          # Node-Commands
│  └─ plugins/           # JS-Plugin Beispiele
├─ templates/            # Microagent-Templates
│  ├─ analyze.md         # Repo-Analyse
│  ├─ send-to-claude.md  # Init-Prompt
│  ├─ talk-to-claude.md  # Follow-up
│  └─ ...               # index, test, next, guardrails
└─ env.example           # Beispiel-Env
```

---

## 📖 Configuration

Die CLI liest `~/.config/smolit_dev/.env` (ENV-Layering).

**Wichtige Variablen:**
* `WORKSPACE` – wird als `/workspace` in OpenHands gemountet
* `LM_BASE_URL` – z. B. LM Studio: `http://127.0.0.1:1234/v1`
* Ports: `OH_PORT`, `SEQ_PORT`, `MEM_PORT`, `BRIDGE_PORT`
* `CLAUDE_API_KEY` / `CODEX_API_KEY` – werden an die Bridge exportiert
* `CLAUDE_MD_PATH` – zusätzliche System-Prompt-Datei
* `OH_IMAGE`, `RUNTIME_IMAGE` – Container-Images (optional anpassbar)

### Microagents

Templates werden nach `$WORKSPACE/.openhands/` kopiert:

- `send-to-claude.md` – Trigger `@init`, ruft Bridge:  
  `http://host.docker.internal:8815/run?file=/workspace/.openhands/prompts/init_prompt.txt`
- `talk-to-claude.md` – Trigger `@c`, ruft Bridge:  
  `http://host.docker.internal:8815/run?file=/workspace/.openhands/prompts/followup_prompt.txt`

---

## 🧑‍💻 Developer Guide

### Plugin Development

**Bash-Plugin erstellen:**
```bash
# ~/.config/smolit_dev/plugins/my-plugin/plugin.sh
my_custom_command() {
  echo "Custom command with args: $*"
  # Access all sd modules and functions
  ensure_oh_dirs
  start_bridge
  send_to_bridge_prompt "Custom analysis request"
}

sd_register "my:custom" "My custom command" my_custom_command
```

**Plugin aktivieren:**
```bash
sd my:custom arg1 arg2    # Automatisch verfügbar
sd --help                 # Zeigt alle Plugins
```

### Module Development

**Neues Modul hinzufügen:**
```bash
# lib/my-feature.sh
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

my_feature_cmd() {
  log "Running my feature..."
  # Use other modules: ensure_oh_dirs, start_bridge, etc.
}

# Register commands
sd_register "my-feature" "Custom feature" my_feature_cmd
```

### Linting & Testing

```bash
# Shell-Linting
npm run lint:shell       # shellcheck lib/*.sh plugins/**/*.sh

# Node-Linting  
npm run lint             # eslint

# Tests
npm test                 # Smoke-Tests
npm run test:modules     # Syntax-Check aller Module
./bin/sd --help          # Live-Test
```

### CI Integration

```bash
# package.json scripts
"prepack": "chmod +x bin/sd bin/bridge.mjs bin/postinstall.mjs bin/sd-launch.cjs",
"test": "node tests/run-tests.mjs",
"lint:shell": "find lib plugins -name '*.sh' -exec shellcheck {} +",
"test:modules": "bash -n lib/*.sh && echo 'All modules syntax OK'"
```

---

## 🪟🍎 Cross-Platform Support

**Windows:** Node-Launcher startet automatisch Git Bash (`bin/sd-launch.cjs`)
**macOS/Linux:** Nativer Bash-Support

### Troubleshooting

**Port belegt:**
```bash
sd ports doctor
```

**Docker Berechtigungen (Linux):**
```bash
sudo usermod -aG docker $USER  # + neu anmelden
```

**Git Bash nicht gefunden (Windows):**
```bash
# PowerShell
setx GIT_BASH "C:\Program Files\Git"
```

**Bridge-Probleme:**
```bash
sd probe-bridge          # Route-Detection
sd logs -f               # Live-Logs
```

---

## 🧪 Testing & Validation

### Quick Tests
```bash
./bin/sd --help                    # Command-Registry
./bin/sd example:echo test         # Plugin-System  
./bin/sd deps doctor               # Dependencies
./bin/sd ports doctor              # Port-Conflicts
npm test                           # Full test suite
```

### Module Tests
```bash
bash -n lib/*.sh                   # Syntax validation
source lib/core.sh && echo "✓"     # Manual loading
npm run test:modules               # Automated check
```

### Integration Tests
```bash
sd up              # Full stack (needs Docker)
sd status          # Health validation
sd probe-bridge    # Bridge connectivity
sd analyze         # AI workflow
sd stop            # Clean shutdown
```

---

## 📈 Migration from v0.1.x

✅ **Zero Breaking Changes** – alle bestehenden Kommandos funktionieren identisch.

**Was ist neu:**
- Modulare Architektur (`lib/*.sh`)  
- Plugin-System (`plugins/`)
- Node-CLI Skeleton (`src/`)
- Erweiterte Tests & Documentation

**Migration:**
```bash
npm update -g smolit-dev    # v0.2.x
sd --help                   # Funktioniert wie vorher
sd example:echo test        # Neues Plugin-Feature
```

---

## 📜 License

MIT License

## 🤝 Contributing

1. Fork & Clone
2. `npm install`
3. Entwickle in `lib/*.sh` (Bash) oder `src/` (Node)  
4. `npm test && npm run lint:shell`
5. PR mit Tests

**Plugin-Beiträge:** Gerne! Lege sie in `plugins/community/` ab.

---

## 🔗 Links

- [NPM Package](https://npmjs.com/package/smolit-dev)
- [GitHub Repository](https://github.com/161sam/smolit_dev_pkg)
- [Issue Tracker](https://github.com/161sam/smolit_dev_pkg/issues)
- [Anthropic Claude](https://claude.ai)
- [OpenHands](https://github.com/All-Hands-AI/OpenHands)

---

**Version 0.2.0** - Modular Architecture Release  
**Maintainer:** [161sam](https://github.com/161sam)  
**Status:** Production Ready, Plugin-System Experimental
