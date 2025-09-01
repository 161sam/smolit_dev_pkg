---
triggers:
  - "@policy"
  - "@guardrails"
---

# Zweck
Erzwinge Sicherheits- und Qualitätsregeln (Scope, Budget, Destructive Ops).

# Regeln
- Keine Lösch- oder Migrationsbefehle ohne Backup-Hinweis & Plan.
- Max Scope per Turn: 5 Files / 200 LOC / 20min.
- Immer Akzeptanzkriterien prüfen.
- Immer Abschluss-Summary mit <changes>, <tests>, <risks>.

