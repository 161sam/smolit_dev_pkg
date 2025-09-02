# DWH dbt Runbook

## Setup
- Kopiere `profiles.example.yml` nach `profiles.yml` und passe ggf. `DBT_DUCKDB_PATH` an.
- Setze `DBT_PROFILES_DIR` auf `etl/dbt` oder starte Befehle in diesem Verzeichnis.

## Build & Tests
```bash
dbt deps
dbt seed --full-refresh --vars '{db_schema_raw: seed, db_schema_seed: seed}'
dbt run --vars '{db_schema_raw: seed}'
dbt test --vars '{db_schema_raw: seed}'
```

## Snapshots
```bash
dbt snapshot --vars '{db_schema_raw: seed}'
```

## Docs
```bash
dbt docs generate --vars '{db_schema_raw: seed}'
```

Die generierte Seite liegt unter `etl/dbt/target/index.html`.
