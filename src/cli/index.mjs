#!/usr/bin/env node
// src/cli/index.mjs - Node CLI entry point (Phase 2)
import path from "node:path";
import { fileURLToPath } from "node:url";

// Simple environment loading (compatible with loadEnv.mjs)
const loadEnv = () => {
  const env = process.env;
  return {
    WORKSPACE: env.WORKSPACE || process.cwd(),
    CONF_DIR: path.join(env.XDG_CONFIG_HOME || env.HOME + "/.config", "smolit_dev"),
    OH_PORT: Number(env.OH_PORT || 3311),
    SEQ_PORT: Number(env.SEQ_PORT || 8811),
    MEM_PORT: Number(env.MEM_PORT || 8812),
    BRIDGE_PORT: Number(env.BRIDGE_PORT || 8815),
    LM_BASE_URL: env.LM_BASE_URL || "http://127.0.0.1:1234/v1",
    SD_ALLOWED_TOOLS: env.SD_ALLOWED_TOOLS || "sequential-thinking,memory-shared,memory,codex-bridge"
  };
};

const env = loadEnv();

// Simple argument parsing
const args = process.argv.slice(2);
const command = args[0] || "help";

// Command registry
const commands = new Map();

// Register a command
const register = (name, handler, description = "") => {
  commands.set(name, { handler, description });
};

// Load built-in commands (simplified for now)
register("version", async () => {
  console.log("sd Node CLI v0.2.0 (Phase 2 prototype)");
}, "Show version");

register("env", async () => {
  console.log("Environment:", JSON.stringify(env, null, 2));
}, "Show environment");

register("bridge:probe", async (args) => {
  const base = args[0] || `http://127.0.0.1:${env.BRIDGE_PORT}`;
  console.log(`Probing Bridge @ ${base}`);
  
  const targets = ["/run", "/run-file", "/api/run"];
  for (const path of targets) {
    try {
      const response = await fetch(base + path + "?prompt=PING");
      console.log(`${response.ok ? "✓" : "✗"} GET ${path} (${response.status})`);
    } catch (error) {
      console.log(`✗ GET ${path} (${error.message})`);
    }
  }
}, "Bridge route detection");

// Dispatch
if (command === "help" || command === "--help" || command === "-h") {
  console.log("sd Node CLI (Phase 2 - Experimental)");
  console.log("Usage: node src/cli/index.mjs <command> [args...]");
  console.log("\nCommands:");
  for (const [name, { description }] of commands) {
    console.log(`  ${name.padEnd(20)} ${description}`);
  }
  console.log("\nNote: This is experimental. Use ./bin/sd for production.");
} else if (commands.has(command)) {
  const { handler } = commands.get(command);
  try {
    await handler(args.slice(1), env);
  } catch (error) {
    console.error(`Error in command '${command}':`, error.message);
    process.exit(1);
  }
} else {
  console.error(`Unknown command: ${command}`);
  console.error("Use 'node src/cli/index.mjs help' to see available commands");
  process.exit(1);
}