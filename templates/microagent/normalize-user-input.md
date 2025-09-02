# Normalize User Input

## Zweck
Wandle unstrukturierten Nutzertext in ein striktes Prompt-Schema um.

## Schritte
- Extrahiere: &lt;GOAL&gt;, &lt;CONTEXT&gt;, &lt;CONSTRAINTS&gt;, &lt;ARTIFACTS&gt;, &lt;REPOS&gt;, &lt;TOOLS&gt;, &lt;RISK&gt;, &lt;DEFINITION_OF_DONE&gt;, &lt;PREFERRED_STYLE&gt;.
- Validiere gegen /workspace/.openhands/prompt-schema.json.
- Schreibe Ergebnis nach: **/workspace/.openhands/normalized_input.xml**
- Logge eine kurze Zusammenfassung nach: **/workspace/.openhands/last_task_summary.txt**

## Context
- Projekt: {{PROJECT}}
- Workspace: {{WORKSPACE}}
- Datum: {{DATE_ISO}}