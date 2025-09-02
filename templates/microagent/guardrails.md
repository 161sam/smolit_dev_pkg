# Guardrails & Policy

## Zweck
Erzwinge Sicherheits- und Qualitätsregeln (Scope, Budget, Destructive Ops).

## Regeln
- Keine Lösch- oder Migrationsbefehle ohne Backup-Hinweis & Plan.
- Max Scope per Turn: 5 Files / 200 LOC / 20min.
- Immer Akzeptanzkriterien prüfen.
- Immer Abschluss-Summary mit &lt;changes&gt;, &lt;tests&gt;, &lt;risks&gt;.

## Context
- Projekt: {{PROJECT}}
- Workspace: {{WORKSPACE}}
- Datum: {{DATE_ISO}}

## Output Format
&lt;guardrails_check&gt;
  &lt;scope_validation&gt;...&lt;/scope_validation&gt;
  &lt;safety_check&gt;...&lt;/safety_check&gt;
  &lt;recommendations&gt;...&lt;/recommendations&gt;
&lt;/guardrails_check&gt;