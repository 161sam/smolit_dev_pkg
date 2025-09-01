---
triggers:
  - "@c"
  - "@claude-fu"
---

# Zweck
Sende fokussierte Follow-ups (Delta zum letzten Stand), mit kleinem Tool/Patch-Budget.

# Schritte
- Erzeuge Follow-up mit Sektionen:
  <delta>Was hat sich geändert?</delta>
  <questions>max 3, falls zwingend</questions>
  <next_atomic_step>1 konkreter Schritt</next_atomic_step>
- Schreibe nach: **/workspace/.openhands/prompts/followup_prompt.txt**
- Rufe: `http://host.docker.internal:8815/run?file=/workspace/.openhands/prompts/followup_prompt.txt`
- Ende: `--- END_OF_FOLLOWUP ---`
