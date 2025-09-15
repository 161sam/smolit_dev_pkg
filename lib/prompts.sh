#!/usr/bin/env bash
# lib/prompts.sh - Template rendering and prompt functions
set -Eeuo pipefail
IFS=$'\n\t'

# Idempotent sourcing guard
if [[ "${SD_PROMPTS_SH_LOADED:-0}" = "1" ]]; then
  return 0
fi
SD_PROMPTS_SH_LOADED=1

# ===== Microagent Shortcuts =====
cmd_norm() {
  ensure_oh_dirs
  local f="$WORKSPACE/.openhands/prompts/normalize_prompt.txt"
  _render_template "normalize-user-input.md" "$f"
  if [[ -n "${SD_INPUT:-}" ]]; then
    printf "\n<raw_user_input>\n%s\n</raw_user_input>\n" "$SD_INPUT" >> "$f"
  elif [[ ! -t 0 ]]; then
    printf "\n<raw_user_input>\n%s\n</raw_user_input>\n" "$(cat)" >> "$f"
  fi
  echo -e "\n--- END_OF_PROMPT ---" >> "$f"
  start_bridge
  send_to_bridge_file "$f"
}

cmd_claude_init() {
  ensure_oh_dirs
  local f="$WORKSPACE/.openhands/prompts/init_prompt.txt"
  _render_template "send-to-claude.md" "$f"
  echo -e "\n--- END_OF_PROMPT ---" >> "$f"
  start_bridge
  send_to_bridge_file "$f"
}

cmd_codex_brief() {
  ensure_oh_dirs
  local f="$WORKSPACE/.openhands/prompts/codex_brief.txt"
  _render_template "claude-to-codex.md" "$f"
  echo -e "\n--- END_OF_CODEX_BRIEF ---" >> "$f"
  start_bridge
  send_to_bridge_file "$f"
}

cmd_claude_fu() {
  ensure_oh_dirs
  local f="$WORKSPACE/.openhands/prompts/followup_prompt.txt"
  _render_template "talk-to-claude.md" "$f"
  if [[ -n "${SD_INPUT:-}" ]]; then
    printf "\n<delta>\n%s\n</delta>\n" "$SD_INPUT" >> "$f"
  elif [[ ! -t 0 ]]; then
    printf "\n<delta>\n%s\n</delta>\n" "$(cat)" >> "$f"
  fi
  echo -e "\n--- END_OF_FOLLOWUP ---" >> "$f"
  start_bridge
  send_to_bridge_file "$f"
}

cmd_guardrails() {
  ensure_oh_dirs
  local f="$WORKSPACE/.openhands/prompts/guardrails_prompt.txt"
  _render_template "guardrails.md" "$f"
  start_bridge
  send_to_bridge_file "$f"
}

# ===== Repo Helper Commands =====
cmd_analyze() {
  ensure_oh_dirs
  local f="$WORKSPACE/.openhands/analyze_prompt.md"
  _render_template "analyze.md" "$f"
  start_bridge
  send_to_bridge_file "$f"
}

cmd_index() {
  ensure_oh_dirs
  local f="$WORKSPACE/.openhands/index_repo.md"
  _render_template "index.md" "$f"
  start_bridge
  send_to_bridge_file "$f"
}

cmd_test() {
  ensure_oh_dirs
  ( cd "$WORKSPACE" && if command -v pytest >/dev/null 2>&1; then 
      pytest -q | tee ".openhands/test_report.txt"
    else 
      echo "pytest nicht installiert" | tee ".openhands/test_report.txt"
    fi )
  local f="$WORKSPACE/.openhands/test_prompt.md"
  _render_template "test.md" "$f"
  start_bridge
  send_to_bridge_file "$f"
}

cmd_next() {
  ensure_oh_dirs
  local f="$WORKSPACE/.openhands/next_steps.md"
  _render_template "next.md" "$f"
  start_bridge
  send_to_bridge_file "$f"
}

# Register commands
sd_register "norm" "Nutzer-Text normalisieren" cmd_norm
sd_register "claude-init" "Supervisor-Init-Prompt an Claude senden" cmd_claude_init
sd_register "codex-brief" "Übergabe-Briefing an Codex senden" cmd_codex_brief
sd_register "claude-fu" "Follow-up (kleine Schritte) an Claude senden" cmd_claude_fu
sd_register "guardrails" "Guardrails/Policy an Claude senden" cmd_guardrails

sd_register "analyze" "Repo-Analyse starten" cmd_analyze
sd_register "index" "aktuelles Repo indexieren (Knowledge-Map)" cmd_index
sd_register "test" "Tests laufen lassen + Patch-Vorschläge" cmd_test
sd_register "next" "nächste Schritte erzeugen" cmd_next
