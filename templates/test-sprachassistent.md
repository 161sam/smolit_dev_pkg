---
triggers:
  - "@sa-test"
---

# Zweck
Führe Tests aus, fasse Fehler kompakt und erzeuge minimale Fix-Patches.

# Schritte
- Starte `pytest -q` (falls vorhanden), schreibe Log nach **/workspace/.openhands/test_report.txt**
- Generiere Patch-Vorschläge inkl. Datei-Pfaden & Einfüge-Positionen.
- Rufe dann:
  `http://host.docker.internal:8815/run?file=/workspace/.openhands/test_prompt.txt`
