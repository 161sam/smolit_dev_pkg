curl -X POST http://localhost:5678/webhook/sd/bridge \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"Analysiere das Repo und liefere Patches."}'
# oder eine Datei im Workspace:
# -d '{"file":"/workspace/.openhands/index_sprachassistent.txt"}'

