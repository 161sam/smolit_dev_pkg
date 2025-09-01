---
triggers:
  - "@init"
  - "@claude"
---

# Zweck
Forme unstrukturierten Nutzerinput zu einem **Init-Prompt** für Claude (Supervisor).

# Schritte
- Erzeuge den Init-Prompt (GOAL/CONTEXT/REPO/AGENTS.md/MCP/Deliverables).
- Schreibe ihn nach: **/workspace/.openhands/init_prompt.txt**
- **Rufe dann** per Browser-Tool folgende URL auf und poste den Textinhalt der Antwort:
  `http://host.docker.internal:8815/run?file=/workspace/.openhands/init_prompt.txt`

