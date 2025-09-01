---
triggers:
  - "@codex-brief"
---

# Zweck
Konvertiere Claudes Plan in einen **präzisen Codex-Arbeitsauftrag**.

# Schritte
- Input: **/workspace/.openhands/prompts/init_prompt.txt** + ggf. **/workspace/.openhands/normalized_input.xml**
- Erzeuge einen Output im Format:

<codex_task>
  <role>Senior Python/TS Engineer</role>
  <repo_context>{{WORKSPACE}}</repo_context>
  <scope max_files="5" max_loc="200"/>
  <style>
    - Patch-Format: minimierte Diffs/Blocks, mit klaren Insert-Positions.
    - Keine Platzhalter, lauffähiger Code.
  </style>
  <tasks>
    <task path="...">…</task>
  </tasks>
  <validation>
    - run: tests/lint/build falls vorhanden
    - artifacts: README/CHANGELOG Updates falls nötig
  </validation>
  <done_when>
    - Kriterien aus <acceptance_criteria>
  </done_when>
</codex_task>

- Schreibe nach: **/workspace/.openhands/prompts/codex_brief.xml**
- Markiere Ende mit `--- END_OF_CODEX_BRIEF ---`

