---
triggers:
  - "@c"
  - "@claude-fu"
---

# Zweck
Nimm den Nutzertext als **Follow-up** zur laufenden Aufgabe und führe Claude aus.

# Schritte
- Erzeuge den Folgeprompt (kurz & fokussiert).
- Schreibe ihn nach: **/workspace/.openhands/followup_prompt.txt**
- **Rufe dann** per Browser-Tool diese URL auf und poste den Textinhalt der Antwort:
  `http://host.docker.internal:8815/run?file=/workspace/.openhands/followup_prompt.txt`

