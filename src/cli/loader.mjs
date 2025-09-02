// src/cli/loader.mjs - Command and plugin loader
import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

export async function loadCommands(register, env) {
  // Example: Register a simple bridge probe command
  register("bridge:probe", async (args, env) => {
    const { probeBridge } = await import("../commands/bridge/probe.mjs");
    await probeBridge(args, env);
  }, "Routen-/Methoden-Autodetect für Bridge");

  register("version", async () => {
    console.log("sd Node CLI v0.1.0 (Phase 2 prototype)");
  }, "Show version");
}

export async function loadPlugins(register, env) {
  const dirs = [
    path.join(env.CONF_DIR || process.env.HOME + "/.config/smolit_dev", "plugins"),
    path.join(env.WORKSPACE || process.cwd(), ".sd", "plugins"),
  ];

  for (const d of dirs) {
    try {
      const items = await fs.readdir(d, { withFileTypes: true });
      for (const it of items) {
        if (it.isDirectory()) {
          const entry = path.join(d, it.name, "index.mjs");
          try {
            const module = await import(pathToFileURL(entry));
            if (module.register) {
              module.register(register, env);
            }
          } catch (error) {
            // Silently ignore plugin loading errors
          }
        }
      }
    } catch (error) {
      // Directory doesn't exist, ignore
    }
  }
}