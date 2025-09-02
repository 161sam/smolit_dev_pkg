# SD CLI Modularisierung - Migration Guide

## Was hat sich geändert?

✅ **Für Endnutzer: NICHTS** - alle `sd`-Kommandos funktionieren identisch
✅ **Für Entwickler: Modular** - Code ist jetzt in `lib/*.sh` aufgeteilt

## Architektur Vorher/Nachher

### Vorher (Monolith)
```
bin/sd (560+ Zeilen) - alles in einer Datei
```

### Nachher (Modular) 
```
bin/sd (30 Zeilen)   - dünner Dispatcher
lib/*.sh             - thematische Module  
plugins/*/plugin.sh  - erweiterbar
src/                 - Node-CLI Skeleton (Phase 2)
```

## Was ist passiert?

1. **Extraktion**: Monolithisches `bin/sd` → `lib/*.sh` Module
2. **Registry**: Command-Registry mit `sd_register`
3. **Plugin-System**: Automatische Plugin-Discovery
4. **Node-Vorbereitung**: Skeleton für zukünftiges Node-CLI

## Wenn etwas nicht funktioniert

1. **Backup wiederherstellen**: `bin/sd.bak.modular-migration`
2. **Debug**: `bash -x bin/sd --help` 
3. **Module prüfen**: `bash -n lib/*.sh`

## Development

### Neues Kommando hinzufügen
```bash
# lib/my-feature.sh
my_new_command() {
  echo "Hello from new command"
}
sd_register "my:new" "Mein neues Kommando" my_new_command
```

### Plugin erstellen
```bash
# plugins/my-plugin/plugin.sh
my_plugin_cmd() { echo "Plugin command"; }
sd_register "my:plugin" "Plugin Kommando" my_plugin_cmd
```

## Node-CLI (Optional, Phase 2)

Falls später gewünscht:
```bash
# Node-CLI aktivieren
SD_NODE_CLI=1 sd --help
node src/cli/index.mjs version
```

## Tests

Alle bestehenden Tests sollten weiterhin funktionieren:
```bash
npm test
./bin/sd --help
./bin/sd up --help
```