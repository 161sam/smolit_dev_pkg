# Prompt-Pipeline Runbook (OpenHands → Claude → Codex)

1) @normalize → schreibt normalized_input.xml nach Schema.
2) @init (@claude) → init_prompt.txt (Supervisor-Plan + codex_brief Stub).
3) @codex-brief → codex_brief.xml (präzise Codex-Anweisung).
4) @c (@claude-fu) → iteratives Follow-up (kleine Schritte).
Artefakte: /workspace/.openhands/[...]

