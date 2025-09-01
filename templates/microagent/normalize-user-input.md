---
triggers:
  - "@norm"
  - "@normalize"
---

# Zweck
Wandle unstrukturierten Nutzertext in ein striktes Prompt-Schema um.

# Schritte
- Extrahiere: <GOAL>, <CONTEXT>, <CONSTRAINTS>, <ARTIFACTS>, <REPOS>, <TOOLS>, <RISK>, <DEFINITION_OF_DONE>, <PREFERRED_STYLE>.
- Validiere gegen /workspace/.openhands/prompt-schema.json.
- Schreibe Ergebnis nach: **/workspace/.openhands/normalized_input.xml**
- Logge eine kurze Zusammenfassung nach: **/workspace/.openhands/last_task_summary.txt**

