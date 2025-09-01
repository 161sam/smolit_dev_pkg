# smolit_dev (`sd`)

One-command Dev-Stack für **OpenHands + MCP (SSE) + Claude-Bridge** – mit GUI & CLI.

## Features

- Startet **OpenHands GUI**, **MCP Sequential Thinking** & **Memory** (via `supergateway`)
- HTTP-Bridge zu **Claude Code** (`@anthropic-ai/claude-code`) – aus GUI/Microagents nutzbar
- Repl/CLI: `sd start-repl`, `sd send init …`, `sd send c …`
- Konfig per `~/.config/smolit_dev/.env`
- Unterstützt LM Studio (OpenAI-kompatible API) – `sd llm list|use`

## Voraussetzungen

- **Node.js ≥ 18**, `npm`, `npx`
- **Docker** (für OpenHands)
- `curl` (und optional `jq`)
- LM Studio o. ä. unter `LM_BASE_URL` (Standard: `http://127.0.0.1:1234/v1`)

## Installation 

**lokal**
```bash
npm i -g .
````
**npm**
```bash
npm i -g smolit-dev
````
**GitHub**
```bash
npm i -g github:161sam/smolit_dev_pkg
````

> Bei erstem Install fragt das `postinstall`-Script optional, ob globale CLIs
> `@anthropic-ai/claude-code` und `@openai/codex` installiert werden sollen.
> Nicht nötig, da `sd` lokal/npx fallbackt – aber bequem.

## Schnellstart

```bash
sd keys init        # API-Keys setzen (optional, kann auch später)
sd llm list         # Modelle aus LM Studio anzeigen
sd llm use <id>     # Modell wählen
sd up               # Stack im Hintergrund + Browser öffnen (GUI)
# oder:
sd start            # Stack im Vordergrund (Logs)
```

**GUI-Shortcuts (Chat):**

* `@init <Ziel>` → baut Init-Prompt & startet Claude über die Bridge
* `@c <Follow-up>` → Folgeprompt schicken

**Terminal:**

```bash
sd start-repl       # interaktive Session (GUI parallel nutzbar)
sd send init "GOAL: …"
sd send c    "Bitte ändere …"
```

## Konfiguration

Die CLI liest `~/.config/smolit_dev/.env`. Vorlage:

```bash
cp env.example ~/.config/smolit_dev/.env
```

Wichtige Variablen:

* `WORKSPACE` – wird als `/workspace` in OpenHands gemountet (nur dieses Verzeichnis)
* `LM_BASE_URL` – z. B. LM Studio: `http://127.0.0.1:1234/v1`
* Ports: `OH_PORT`, `SEQ_PORT`, `MEM_PORT`, `BRIDGE_PORT`
* `CLAUDE_API_KEY` / `CODEX_API_KEY` – werden als `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` an die Bridge exportiert
* `CLAUDE_MD_PATH` – zusätzliche System-Prompt-Datei für Claude
* `OH_IMAGE`, `RUNTIME_IMAGE` – Container-Images (optional anpassbar)

## Microagents

Beim Start kopiert `sd` Templates nach
`$WORKSPACE/.openhands/microagents/` (falls nicht vorhanden):

* `send-to-claude.md` – Trigger `@init`, schreibt `init_prompt.txt`, ruft Bridge:
  `http://host.docker.internal:8815/run?file=/workspace/.openhands/init_prompt.txt`
* `talk-to-claude.md` – Trigger `@c`, schreibt `followup_prompt.txt`, ruft Bridge:
  `http://host.docker.internal:8815/run?file=/workspace/.openhands/followup_prompt.txt`

> Wichtig: Der OpenHands-Container erreicht den Host via
> `host.docker.internal` (in `sd` bereits mit `--add-host …` gesetzt).

## Nützliche Befehle

```bash
sd status            # PIDs/Containerstatus
sd logs              # Logverzeichnis anzeigen
sd stop              # alles stoppen
sd deps doctor       # Abhängigkeits-Check
```

Health-Checks:

```bash
curl -sSf http://127.0.0.1:3311       # GUI
curl -sSf http://127.0.0.1:8811/healthz  # SSE seq
curl -sSf http://127.0.0.1:8812/healthz  # SSE mem
curl -sSf http://127.0.0.1:8815/healthz  # Bridge
```

## Troubleshooting

* **GUI loggt `0.0.0.0:3000`**: Das ist normal (Container-intern). Lokal öffnest du
  `http://127.0.0.1:3311`.
* **Bridge 400/invalid file**: Pfade **müssen** mit `/workspace/…` beginnen.
  Die Bridge mappt auf `$WORKSPACE`.
* **`claude` nicht gefunden**: Die Bridge fällt auf `npx @anthropic-ai/claude-code` zurück.
  Optional global installieren:
  `npm i -g @anthropic-ai/claude-code @openai/codex`
* **Docker-Permissions**: ggf. User zur `docker`-Gruppe hinzufügen und neu einloggen.

## Deinstallation

```bash
npm uninstall -g @smolit/_dev
```

Optional: Konfig löschen

```bash
rm -rf ~/.config/smolit_dev ~/.openhands/logs ~/.mcp/memory
```

## Lizenz

MIT

---
