#!/usr/bin/env node
import {existsSync, mkdirSync, copyFileSync, writeFileSync} from "node:fs";
import {fileURLToPath} from "node:url";
import path from "node:path";
import {spawnSync} from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DRY = process.argv.includes("--dry-run");

// Respect CI/skips to avoid side-effects in automated environments
const shouldSkip = () => {
  const env = process.env;
  if (DRY) return false; // allow explicit dry-run rendering
  if (env.NO_POSTINSTALL === '1' || env.NO_POSTINSTALL === 'true') return true;
  if (env.SKIP_POSTINSTALL === '1' || env.SKIP_POSTINSTALL === 'true') return true;
  if (env.CI === '1' || (env.CI || '').toLowerCase() === 'true') return true;
  return false;
};

if (shouldSkip()) {
  console.log('[postinstall] skipped due to CI/NO_POSTINSTALL/SKIP_POSTINSTALL');
  process.exit(0);
}
const XDG_CONFIG_HOME = process.env.XDG_CONFIG_HOME || path.join(process.env.HOME || "~", ".config");
const XDG_STATE_HOME  = process.env.XDG_STATE_HOME  || path.join(process.env.HOME || "~", ".local/state");
const XDG_CACHE_HOME  = process.env.XDG_CACHE_HOME  || path.join(process.env.HOME || "~", ".cache");

const CONF_DIR = path.join(XDG_CONFIG_HOME, "smolit_dev");
const STATE_DIR = path.join(XDG_STATE_HOME, "smolit_dev");
const CACHE_DIR = path.join(XDG_CACHE_HOME, "smolit_dev");
const LOG_DIR = path.join(STATE_DIR, "logs");
const PID_DIR = path.join(STATE_DIR, "pids");

for (const d of [CONF_DIR, STATE_DIR, CACHE_DIR, LOG_DIR, PID_DIR]) {
  if (!existsSync(d)) {
    if (!DRY) mkdirSync(d, {recursive:true});
    else console.log(`[postinstall] would mkdir ${d}`);
  }
}

const envExample = path.resolve(__dirname, "../env.example");
const envTarget  = path.join(CONF_DIR, ".env");
if (!existsSync(envTarget)) {
  if (!DRY) copyFileSync(envExample, envTarget);
  console.log(`[postinstall] ${existsSync(envTarget) ? "created" : "would create"} ${envTarget}`);
}

function ensureGlobal(name) {
  const which = spawnSync(process.platform === "win32" ? "where" : "which", [name], {stdio:"pipe"});
  return which.status === 0;
}

// Optional: Hinweis auf globale CLIs (nicht zwingend)
for (const pkg of ["@anthropic-ai/claude-code"]) {
  if (!ensureGlobal("claude")) {
    console.log(`[postinstall] Hinweis: Du kannst optional 'npm i -g ${pkg}' installieren (sd fällt sonst auf npx zurück).`);
  }
}

console.log("[postinstall] done.");
