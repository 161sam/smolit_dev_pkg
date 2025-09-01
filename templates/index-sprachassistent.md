---
triggers:
  - "@sa-index"
---

# Zweck
Erstelle eine **Knowledge-Map** des Sprachassistenten:
- Module/Dateien, zentrale Funktionen, Datenflüsse (STT -> LLM -> TTS), wichtige Consts/ENV.
- Offene TODOs + Fundstellen.

# Schritte
- Scanne Repo strukturiert (Ordner/Dateien, Code, README/TODOs)
- Schreibe Ergebnis nach: **/workspace/.openhands/index_sprachassistent.txt**
- Rufe dann:
  `http://host.docker.internal:8815/run?file=/workspace/.openhands/index_sprachassistent.txt`
