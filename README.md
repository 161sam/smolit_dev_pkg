# smolit_dev_pkg (sd)

**sd** ist ein schlanker Dev-Orchestrator:  
👉 Startet **OpenHands** (Docker), verbindet **MCP (Sequential Thinking + Memory)** und bietet eine **Claude-Bridge** per HTTP.  
Dazu kommt eine **CLI** mit nützlichen Subcommands für Entwickler*innen und Microagent-Templates.  

---

## 🚀 Quickstart

```bash
npm install -g .
sd deps doctor
sd up          # Startet OpenHands (Docker) + Bridge
sd status      # Health-Check (GUI, MCP, Bridge)
````

GUI: [http://127.0.0.1:3311](http://127.0.0.1:3311)
Bridge: [http://127.0.0.1:8815/healthz](http://127.0.0.1:8815/healthz)

---

## ⚙️ Installation & Setup

### 1. Environment


**Installation lokal**
```bash
npm i -g .
````
**Installation GitHub**
```bash
npm i -g github:161sam/smolit_dev_pkg
````
**Setup**
```bash
sd keys init
```

### 2. Docker

* OpenHands Container (`openhands/supergateway`) wird automatisch gestartet.
* Ports:

  * GUI: `3311`
  * MCP Sequential: `8811`
  * MCP Memory: `8812`
  * sd-Bridge: `8815`

### 3. Node.js

* Erfordert Node >= 18
* Installiert sich als globales CLI (`sd`).

**Installation npm**
```bash
npm i -g smolit-dev
````

---

## 🔄 Die sd-Pipeline

Die `sd`-Pipeline verbindet Eingaben, Analyse und KI-Tools:

1) **User Input (unstrukturiert)**
   * *Einfacher Text oder Datei-Inhalt.*
2) **OpenHands (strukturierend)**
   * Läuft in Docker
   * Erkennt Intentionen und strukturiert unklare Eingaben
   * Baut daraus einen validierten Prompt
3) **Claude als Supervisor**
   * Empfängt den strukturierten Prompt von OpenHands
   * Agiert als „Supervisor“ und orchestriert die Arbeit
   * Entscheidet, welche Tools/Aktionen erforderlich sind
4) **Codex als Worker**
   * Claude beauftragt Codex (oder ein anderes Modell) mit konkreten Aufgaben
   * Codex führt Code-Analysen, Patch-Erstellung und Refactorings durch
   * Ergebnisse werden zurück in den Pipeline-Kontext gespielt
5) **Memory (MCP)**
   * Erkenntnisse und Ergebnisse werden ins MCP Memory geschrieben
   * Bleiben für spätere Iterationen abrufbar

Ergebnis: **Von unstrukturiertem Userinput → strukturierter Prompt → konkrete Patches & Next Steps.**

---

## 🖥️ CLI

```bash
sd up              # OpenHands + Bridge starten, GUI öffnen
sd start           # wie 'up', ohne GUI-Open
sd stop            # Container & Bridge stoppen
sd status          # Health-Check
sd logs            # zeigt Log-Verzeichnis
sd deps doctor     # prüft Dependencies
sd ports doctor    # Port-Kollisionen prüfen

sd project init    # .claude/settings.json für MCP erzeugen
sd mcp status      # MCP-Status prüfen

sd analyze         # Repo-Analyse starten
sd index           # aktuelles Repo indexieren (Knowledge-Map)
sd test            # Tests laufen lassen + Patches
sd next            # nächste Schritte erzeugen
```

---

## 🔒 Sicherheit

* **Standardmäßig KEIN** `--dangerously-skip-permissions`.
* Optional via `SD_BYPASS_PERMISSIONS=1` aktivierbar.
* Bridge erlaubt nur Tools:

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

## 📂 Struktur

```
bin/sd              # CLI Entry
bin/bridge.mjs      # HTTP Bridge (Claude/MCP)
bin/postinstall.mjs # Idempotentes Setup
templates/          # Microagent-Templates
env.example         # Beispiel-Env
```

---

## 🧑‍💻 Developer Guide

* **Linting**:

  ```bash
  npm run lint:shell
  npm run lint:node
  ```
* **CI Smoke-Test**:

  ```bash
npm run ci:smoke
```

Postinstall-Schutz in CI/Headless-Umgebungen: setze `NO_POSTINSTALL=1` oder `SKIP_POSTINSTALL=1` (wird automatisch in CI beachtet).
* **Packaging-Test**:

  ```bash
  npm pack
  ```

---

## 📖 User Handbook

### Starten

```bash
sd up
```

Öffnet GUI + startet Bridge. Danach können Prompts via Flowise oder n8n durchgereicht werden.

### Konfiguration

Die CLI liest `~/.config/smolit_dev/.env`. 

Wichtige Variablen:

* `WORKSPACE` – wird als `/workspace` in OpenHands gemountet (nur dieses Verzeichnis)
* `LM_BASE_URL` – z. B. LM Studio: `http://127.0.0.1:1234/v1`
* Ports: `OH_PORT`, `SEQ_PORT`, `MEM_PORT`, `BRIDGE_PORT`
* `CLAUDE_API_KEY` / `CODEX_API_KEY` – werden als `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` an die Bridge exportiert
* `CLAUDE_MD_PATH` – zusätzliche System-Prompt-Datei für Claude
* `OH_IMAGE`, `RUNTIME_IMAGE` – Container-Images (optional anpassbar)

### Microagents

Beim Start kopiert `sd` Templates nach
`$WORKSPACE/.openhands/microagents/` (falls nicht vorhanden):

* `send-to-claude.md` – Trigger `@init`, schreibt `init_prompt.txt`, ruft Bridge:
  `http://host.docker.internal:8815/run?file=/workspace/.openhands/init_prompt.txt`
* `talk-to-claude.md` – Trigger `@c`, schreibt `followup_prompt.txt`, ruft Bridge:
  `http://host.docker.internal:8815/run?file=/workspace/.openhands/followup_prompt.txt`

> Wichtig: Der OpenHands-Container erreicht den Host via
> `host.docker.internal` (in `sd` bereits mit `--add-host …` gesetzt).

### Health-Checks:

```bash
curl -sSf http://127.0.0.1:3311       # GUI
curl -sSf http://127.0.0.1:8811/healthz  # SSE seq
curl -sSf http://127.0.0.1:8812/healthz  # SSE mem
curl -sSf http://127.0.0.1:8815/healthz  # Bridge
```

### Typische Probleme

* **Port belegt** → `sd ports doctor`
* **Docker nicht läuft** → `systemctl start docker`
* **Bridge EPIPE** → wird automatisch mit Retry behandelt

### Troubleshooting

* **GUI loggt `0.0.0.0:3000`**: Das ist normal (Container-intern). Lokal öffnest du
  `http://127.0.0.1:3311`.
* **Bridge 400/invalid file**: Pfade **müssen** mit `/workspace/…` beginnen.
  Die Bridge mappt auf `$WORKSPACE`.
* **`claude` nicht gefunden**: Die Bridge fällt auf `npx @anthropic-ai/claude-code` zurück.
  Optional global installieren:
  `npm i -g @anthropic-ai/claude-code @openai/codex`
* **Docker-Permissions**: ggf. User zur `docker`-Gruppe hinzufügen und neu einloggen.

### Logs

```bash
~/.local/state/smolit_dev/logs/
```

### Uninstall

```bash
npm uninstall -g .
rm -rf ~/.config/smolit_dev ~/.local/state/smolit_dev ~/.cache/smolit_dev
```

---

## 🪟🍎 Windows & macOS Hinweise

Diese Sektion fasst die plattformspezifischen Punkte für **sd** zusammen.

---

### Voraussetzungen

**macOS**
- Node.js ≥ 18 (`brew install node`)
- Docker Desktop (mit „Use gRPC FUSE“ aktiviert empfohlen)
- (Optional) LM Studio für lokales LLM

**Windows (2 Optionen)**
1) **Native (empfohlen, wenn Git Bash vorhanden)**  
   - Node.js ≥ 18 (Windows x64 MSI)  
   - **Docker Desktop** (Linux-Container-Modus)  
   - **Git for Windows** (inkl. **Git Bash**)
2) **WSL2** (Alternative, sehr stabil)  
   - Windows 10/11 + WSL2 + Ubuntu  
   - Node.js + Docker Engine innerhalb von WSL2  
   - `sd` läuft dann wie unter Linux

> **Hinweis:** Der mitgelieferte **Node-Launcher** startet unter Windows automatisch die Bash (`bin/sd-launch.js`). Du kannst optional den Pfad zu Git Bash via `GIT_BASH` setzen.

---

### Installation

```bash
# macOS / Linux
npm install -g .

# Windows (PowerShell oder CMD; nutzt Node-Launcher → Git Bash)
npm install -g .
```

Erstcheck:

```bash
sd deps doctor
```

---

### Start/Stop

```bash
sd up         # OpenHands + Bridge starten, Browser öffnen
sd status     # Health-Check
sd stop       # Stack stoppen
```

Browser-Open:

* macOS nutzt intern `open`, Linux `xdg-open`, Windows `start` (alles automatisch).

---

### Pfade & Shell (Windows)

* In **Git Bash** sind Pfade **POSIX-artig**: `C:\Users\you\repo` → `/c/Users/you/repo`
* Das Volume-Mounting macht `sd` automatisch: `-v "$WORKSPACE:/workspace"`
* **Tipp:** Räume Leerzeichen in Pfaden durch Anführungszeichen auf:

  ```bash
  WORKSPACE="/c/Users/you/My Project" sd up
  ```

---

### Docker & Networking

* **Linux**: `host.docker.internal` wird von `sd` via `--add-host` gesetzt.
* **macOS/Windows**: `host.docker.internal` ist bereits verfügbar.
* Ports (Standard): GUI `3311`, MCP `8811/8812`, Bridge `8815`.

  ```bash
  sd ports doctor
  ```

---

### LLM-Konfiguration (LM Studio & Co.)

* Standard: `LM_BASE_URL=http://127.0.0.1:1234/v1` (LM Studio Default)
* Modelle anzeigen/setzen:

  ```bash
  sd llm list
  sd llm use gpt-neoxt-20b  # Beispiel
  ```
* Persistent in `~/.config/smolit_dev/.env`:

  ```bash
  sd keys init
  ```

---

### Troubleshooting

* **Port belegt?**

  ```bash
  sd ports doctor
  ```
* **Docker Berechtigungen (Linux):** Benutzer evtl. zur `docker` Gruppe hinzufügen:

  ```bash
  sudo usermod -aG docker $USER
  # danach neu anmelden
  ```
* **Firewall-Prompt (Windows/macOS):** Beim ersten Start zulassen.
* **LM Studio läuft nicht?** Prüfe `LM_BASE_URL`, z. B.:

  ```bash
  http://127.0.0.1:1234/v1/models
  ```
* **Git Bash nicht gefunden (Windows)?** Installiere **Git for Windows** oder setze `GIT_BASH`:

  ```powershell
  setx GIT_BASH "C:\Program Files\Git"
  ```

---

### Performance-Tipp

* Für sehr große Repos/Workloads ist **WSL2** (Windows) oder **Docker Desktop mit Ressourcen-Tuning** (macOS) empfehlenswert.

---

## 📜 License

MIT License

---
