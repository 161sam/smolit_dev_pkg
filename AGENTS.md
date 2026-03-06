# AGENTS.md

## Projektkontext

Dieses Repository entwickelt `smolit_dev_pkg` zu einem modularen, lokal-first Multi-Agent-Orchestrator für Entwicklungs- und Automatisierungs-Workflows weiter.

Die neue Zielarchitektur ist unter `docs/new_design/` dokumentiert:

- `ARCHITECTURE_V2.md`
- `WORKER_MODEL.md`
- `CONFIG_SPEC.md`
- `MIGRATION_PLAN.md`
- `IDE_INTEGRATION_PLAN.md`

Diese Dokumente sind die maßgebliche Referenz für die laufende Migration.

---

## Zielbild

Die Architektur wird auf folgende Rollen umgestellt:

- **Prompt Structuring / Task Normalization**
  - läuft lokal über **LM Studio** bzw. eine **OpenAI-kompatible lokale API**
  - **nicht mehr über OpenHands**

- **Supervisor**
  - **Codex** übernimmt die Supervisor-Rolle
  - Supervisor entscheidet über Routing, Retries, Validierung und Aggregation

- **Standard Worker**
  - **Codex** übernimmt normale / schnelle / kleine Aufgaben

- **Complex Worker**
  - **Claude** übernimmt komplexe, modulübergreifende oder stark reasoning-lastige Aufgaben

- **Interactive / Specialized Worker**
  - **OpenHands** wird als echter Worker-Typ integriert
  - mehrere Instanzen müssen möglich sein
  - jede Instanz hat definierte Rolle, Scope, Tools und Modus

- **OpenHands Modes**
  - `auto`: Supervisor darf die Agent-Konfiguration festlegen oder anpassen
  - `manual`: User definiert die Konfiguration; Supervisor darf nur Aufgaben zuweisen, nicht die Konfiguration überschreiben

---

## Verbindliche Architekturprinzipien

1. **Local-first**
   - Prompt-Strukturierung soll lokal laufen.
   - Keine unnötige Verlagerung zentraler Planungslogik in externe Agenten.

2. **Protocol-first**
   - interne Komponenten kommunizieren über klar definierte, versionierbare Datenstrukturen
   - keine versteckten impliziten Seiteneffekte zwischen Modulen

3. **Thin Bash**
   - Bash nur für Bootstrap, Dev-Glue, einfache Wrapper
   - Kernlogik gehört in den Core (bevorzugt TypeScript/Node)

4. **Single source of truth**
   - Konfigurationen, Routingregeln und Worker-Spezifikationen dürfen nicht an mehreren Stellen widersprüchlich gepflegt werden

5. **Deterministische Ausführung**
   - Tool-Aufrufe, Build, Tests, Git-Operationen und Validierungen müssen möglichst deterministisch und reproduzierbar sein

6. **Klare Rollentrennung**
   - Structurer strukturiert
   - Supervisor orchestriert
   - Worker führen aus
   - Tools erledigen deterministische Aktionen

7. **IDE readiness**
   - Änderungen sollen die spätere Nutzung als Daemon / API / MCP / IDE-Plugin nicht verbauen

---

## Arbeitsweise für Agenten

Bei allen Änderungen gilt:

- arbeite in **kleinen, klar abgegrenzten Schritten**
- führe **gezielte, minimale Änderungen** pro Arbeitspaket durch
- dokumentiere Architekturentscheidungen direkt im Code oder in Markdown
- behebe Inkonsistenzen nicht nur oberflächlich, sondern vereinheitliche die Struktur
- bevor neue Layer ergänzt werden, müssen widersprüchliche Altpfade identifiziert und bereinigt werden
- keine unnötigen Total-Rewrites
- keine Einführung zusätzlicher Komplexität ohne klaren Nutzen
- keine stillen Breaking Changes ohne Dokumentation

---

## Bevorzugte technische Richtung

### Kurzfristig
- bestehende Architektur bereinigen
- Worker-/Supervisor-/Structurer-Modell sauber einführen
- OpenHands als Worker-Typ ergänzen
- Bash reduzieren, aber nicht blind entfernen

### Mittelfristig
- Core in **TypeScript/Node** konsolidieren
- Bash zu dünnen Wrappern zurückbauen
- Konfigurations- und Routingmodell stabilisieren

### Langfristig
- `sd daemon`
- HTTP API / WebSocket
- MCP-Server
- VS Code / Zed / weitere Editor-Integrationen

---

## Nicht-Ziele

Diese Dinge sollen aktuell **nicht** priorisiert werden:

- kompletter Rewrite des gesamten Projekts in Rust oder Go
- vorschnelles Entfernen funktionierender Bestandteile ohne Migrationspfad
- IDE-spezifische Sonderlogik vor Stabilisierung des protocol-first Cores
- Verlagerung der Prompt-Strukturierung zurück nach OpenHands

---

## Definition of Done

Ein Arbeitspaket ist nur dann wirklich abgeschlossen, wenn:

1. die Implementierung zur Zielarchitektur unter `docs/new_design/` passt
2. Inkonsistenzen mit bestehenden Pfaden erkannt und behandelt wurden
3. Konfiguration und Verhalten nachvollziehbar dokumentiert sind
4. vorhandene Tests angepasst oder neue Tests ergänzt wurden, sofern sinnvoll
5. keine offensichtlichen Dupplikate / Parallelpfade entstehen
6. die Änderung späteren Daemon-/IDE-Betrieb nicht erschwert

---

## Bevorzugte Repo-Konventionen

- kleine, verständliche Commits
- sprechende Dateinamen
- keine unnötig generischen Hilfsfunktionen
- keine Magie-Konfiguration ohne Doku
- strukturierte Logs / Statusmeldungen bevorzugen
- Fehlerpfade explizit behandeln

---

## Architektur-Reihenfolge

Die Umsetzung soll grob in dieser Reihenfolge erfolgen:

1. **Bestandsanalyse & Inkonsistenzen dokumentieren**
2. **Legacy-/Duplikatpfade bereinigen**
3. **Worker Interface / Worker Registry definieren**
4. **Structurer über LM Studio / OpenAI-kompatible lokale API einführen**
5. **Codex Supervisor integrieren**
6. **Codex Standard Worker integrieren**
7. **Claude Complex Worker integrieren**
8. **OpenHands Worker Adapter einführen**
9. **OpenHands Multi-Instance + auto/manual mode**
10. **Routing Rules / Complexity Mapping**
11. **Konfiguration konsolidieren**
12. **Daemon-/API-/IDE-Vorbereitung**

---

## Qualitätsfokus

Besonders wichtig sind:

- klare interne Verträge / Interfaces
- reproduzierbare Konfiguration
- Erweiterbarkeit
- gute Fehlermeldungen
- geringe Kopplung
- saubere Migration statt Quick Hacks

---

## Wenn Unsicherheit besteht

Bei Unsicherheit gilt:

- zuerst die Dokumente unter `docs/new_design/` prüfen
- dann die bestehende Codebasis auf reale Pfade und tatsächliche Nutzung prüfen
- dann die **kleinste robuste Änderung** vorschlagen oder umsetzen, die zur Zielarchitektur passt

Nicht raten. Nicht spekulativ umbauen. Erst Ist-Zustand prüfen, dann gezielt anpassen.
