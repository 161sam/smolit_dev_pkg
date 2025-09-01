---
triggers:
  - "@init"
  - "@claude"
---

# Zweck
Forme das normalisierte Schema zu einem **Init-Prompt** für Claude (Supervisor), inkl. Rollen- und Ausführungsregeln.

# Schritte
- Lies **/workspace/.openhands/normalized_input.xml** (oder nutze Rohtext falls nicht vorhanden).
- Baue einen Prompt mit XML-Blöcken:
  <role>Senior Orchestrator</role>
  <input>…</input>
  <instructions>
    - Du arbeitest im Agentenverbund (Claude→Codex).
    - Nutze knappe, eindeutige Outputs.
    - Keine Rückfragen, triff sinnvolle Annahmen und dokumentiere sie in <assumptions>.
  </instructions>
  <deliverables>
    - <codex_brief>…</codex_brief>
    - <acceptance_criteria>…</acceptance_criteria>
    - <plan>…</plan>
  </deliverables>
  <guardrails>Scope ≤ N Dateien, keine destruktiven Änderungen ohne Backup, Zeitbudget etc.</guardrails>

- Schreibe nach: **/workspace/.openhands/prompts/init_prompt.txt**
- Rufe: `http://host.docker.internal:8815/run?file=/workspace/.openhands/prompts/init_prompt.txt`
- Markiere Ende mit: `\n--- END_OF_PROMPT ---`
