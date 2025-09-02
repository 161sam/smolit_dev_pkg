# Claude → Codex Brief

## Zweck
Konvertiere Claudes Plan in einen **präzisen Codex-Arbeitsauftrag**.

## Schritte
- Input: **/workspace/.openhands/prompts/init_prompt.txt** + ggf. **/workspace/.openhands/normalized_input.xml**
- Erzeuge einen Output im Format:

&lt;codex_task&gt;
  &lt;role&gt;Senior Python/TS Engineer&lt;/role&gt;
  &lt;repo_context&gt;{{WORKSPACE}}&lt;/repo_context&gt;
  &lt;scope max_files="5" max_loc="200"/&gt;
  &lt;style&gt;
    - Patch-Format: minimierte Diffs/Blocks, mit klaren Insert-Positions.
    - Keine Platzhalter, lauffähiger Code.
  &lt;/style&gt;
  &lt;tasks&gt;
    &lt;task path="..."&gt;…&lt;/task&gt;
  &lt;/tasks&gt;
  &lt;validation&gt;
    - run: tests/lint/build falls vorhanden
    - artifacts: README/CHANGELOG Updates falls nötig
  &lt;/validation&gt;
  &lt;done_when&gt;
    - Kriterien aus &lt;acceptance_criteria&gt;
  &lt;/done_when&gt;
&lt;/codex_task&gt;

## Context
- Projekt: {{PROJECT}}
- Workspace: {{WORKSPACE}}
- Datum: {{DATE_ISO}}