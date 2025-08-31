#!/usr/bin/env node
import readline from "node:readline";
import { spawn } from "node:child_process";

function ask(q) {
  return new Promise((res) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question(q, (a) => { rl.close(); res(a.trim()); });
  });
}

function isTTY() {
  return process.stdout.isTTY && !process.env.CI;
}

async function maybeGlobalInstall() {
  if (!isTTY()) {
    console.log("[smolit_dev] Installed. Tip: run `sd keys init` and `sd up`.");
    return;
  }
  console.log("\n[smolit_dev] Optional setup:");
  console.log("  - Claude & Codex global installieren (bequeme Shortcuts `claude`/`codex`)");
  const ans = (await ask("Install global CLIs now? [y/N] ")).toLowerCase();
  if (ans !== "y" && ans !== "yes") return;

  const pkgs = ["@anthropic-ai/claude-code", "@openai/codex"];
  console.log(`[smolit_dev] npm i -g ${pkgs.join(" ")}`);
  const p = spawn("npm", ["i", "-g", ...pkgs], { stdio: "inherit" });
  p.on("close", (code) => {
    if (code === 0) console.log("[smolit_dev] Global install done.");
    else console.log("[smolit_dev] Global install skipped/failed (non-zero exit).");
  });
}

maybeGlobalInstall().catch(() => {});

