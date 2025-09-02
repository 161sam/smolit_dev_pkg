// src/commands/bridge/probe.mjs - Bridge probe command for Node CLI
import { execSync } from "node:child_process";

export async function probeBridge(args, env) {
  const base = args[0] || env.BRIDGE_ENDPOINT_BASE || `http://127.0.0.1:${env.BRIDGE_PORT || 8815}`;
  
  console.log(`Probing Bridge @ ${base}`);
  
  const targets = ["/run", "/run-file", "/api/run", "/v1/run"];
  
  for (const path of targets) {
    try {
      const url = `${base}${path}`;
      const response = await fetch(url + "?prompt=PING", { method: "GET" });
      
      if (response.ok) {
        console.log(`✓ GET ${path} (${response.status})`);
      } else {
        console.log(`✗ GET ${path} (${response.status})`);
      }
    } catch (error) {
      console.log(`✗ GET ${path} (error: ${error.message})`);
    }
  }
  
  console.log("\nNote: This is a prototype Node CLI implementation.");
  console.log("Use the Bash CLI for full functionality: ./bin/sd probe-bridge");
}