# Config & Environment

## Detected environment variables

- From bin/sd:
  - 49:XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  - 50:XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  - 51:XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
  - 60:ENV_FILE="${ENV_FILE:-$CONF_DIR/.env}"
  - 64:WORKSPACE="${WORKSPACE:-$PWD}"
  - 65:WORKSPACE_DEFAULT="${WORKSPACE_DEFAULT:-$HOME/OpenHands_Workspace}"
  - 67:LM_BASE_URL="${LM_BASE_URL:-http://127.0.0.1:1234/v1}"
  - 68:OH_PORT="${OH_PORT:-3311}"
  - 69:SEQ_PORT="${SEQ_PORT:-8811}"
  - 70:MEM_PORT="${MEM_PORT:-8812}"
  - 71:BRIDGE_PORT="${BRIDGE_PORT:-8815}"
  - 72:MEM_FILE="${MEM_FILE:-$HOME/.mcp/memory/memory_shared.json}"
  - 74:OH_IMAGE="${OH_IMAGE:-openhands/supergateway:latest}"
  - 75:OH_NAME="${OH_NAME:-sd_oh}"
  - 76:SD_LLM_MODEL="${SD_LLM_MODEL:-}"   # optional preferred model id
  - 79:SD_BYPASS_PERMISSIONS="${SD_BYPASS_PERMISSIONS:-}"      # set non-empty to allow dangerous perms
  - 80:SD_ALLOWED_TOOLS="${SD_ALLOWED_TOOLS:-sequential-thinking,memory-shared,memory,codex-bridge}"
  - 88:TEMPLATE_DIR="${SD_TEMPLATE_DIR:-$SELF_DIR/../templates}"

- From code (process.env.*):
  - bin/postinstall.mjs:24:const XDG_CONFIG_HOME = process.env.XDG_CONFIG_HOME || path.join(process.env.HOME || "~", ".config");
  - bin/postinstall.mjs:25:const XDG_STATE_HOME  = process.env.XDG_STATE_HOME  || path.join(process.env.HOME || "~", ".local/state");
  - bin/postinstall.mjs:26:const XDG_CACHE_HOME  = process.env.XDG_CACHE_HOME  || path.join(process.env.HOME || "~", ".cache");
  - bin/sd-launch.cjs:12:    process.env.GIT_BASH && path.join(process.env.GIT_BASH, 'bin', 'bash.exe'),
  - bin/sd-launch.cjs:15:    process.env.ProgramW6432 && path.join(process.env.ProgramW6432, 'Git', 'bin', 'bash.exe'),
  - bin/sd-launch.cjs:16:    process.env.ProgramFiles && path.join(process.env.ProgramFiles, 'Git', 'bin', 'bash.exe')
  - reports/BAK_PARITY.md:5:| bin/bridge.mjs.bak.auto | bin/bridge.mjs | --- bin/bridge.mjs	2025-09-01 10:12:14.168524900 +0200 +++ bin/bridge.mjs.bak.auto	2025-08-31 14:59:40.892949255 +0200 @@ -1,109 +1,89 @@ #!/usr/bin/env node import http from "node:http"; +import { readFileSync, existsSync } from "node:fs"; import { spawn } from "node:child_process"; -import { readFile } from "node:fs/promises"; -import { URL } from "node:url"; -import path from "node:path"; - -const arg = (flag, fallback) => { - const i = process.argv.indexOf(flag); - return i !== -1 ? process.argv[i + 1] : fallback; -}; - -const PORT = Number(process.env.BRIDGE_PORT \|\| arg("--port", 8815)); -const WORKSPACE = process.env.WORKSPACE \|\| arg("--workspace", process.cwd()); -const DANGEROUS = process.argv.includes("--dangerously-skip-permissions"); -const ALLOWED = arg("--allowed-tools", process.env.SD_ALLOWED_TOOLS \|\| "sequential-thinking,memory-shared,memory,codex-bridge"); - -const mapWorkspaceFile = (filePath) => { - const norm = path.posix.normalize(filePath); - if (!norm.startsWith("/workspace/")) { - throw new Error(`Pfad muss mit /workspace beginnen: ${filePath}`); - } - const rel = norm.slice("/workspace".length); - const hostPath = path.resolve(path.join(WORKSPACE, rel)); - const wsRoot = path.resolve(WORKSPACE); - if (!hostPath.startsWith(wsRoot)) { - throw new Error("Pfad außerhalb des WORKSPACE"); - } - return hostPath; -}; +import { fileURLToPath } from "node:url"; +import { dirname, join } from "node:path"; + +const PORT = parseInt(process.env.CLAUDE_BRIDGE_PORT \|\| "8815", 10); +const WORKSPACE = process.env.WORKSPACE_ROOT \|\| `${process.env.HOME}/OpenHands_Workspace`; +const CLAUDE_MD = process.env.CLAUDE_MD_PATH \|\| `${process.env.HOME}/CLAUDE.md`;  | high | merge |
  - bin/bridge.mjs:13:const PORT = Number(process.env.BRIDGE_PORT || arg("--port", 8815));
  - bin/bridge.mjs:14:const WORKSPACE = process.env.WORKSPACE || arg("--workspace", process.cwd());
  - bin/bridge.mjs:16:const ALLOWED = arg("--allowed-tools", process.env.SD_ALLOWED_TOOLS || "sequential-thinking,memory-shared,memory,codex-bridge");
  - bin/bridge.mjs:39:    ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY || process.env.CLAUDE_API_KEY || ""

## Notes
- Postinstall honors CI/NO_POSTINSTALL/SKIP_POSTINSTALL.
- Bridge reads ANTHROPIC_API_KEY/CLAUDE_API_KEY; do not log secrets.
- LOG_DIR: ~/.local/state/smolit_dev/logs (bin/sd).
