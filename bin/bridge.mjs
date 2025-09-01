#!/usr/bin/env node
import http from "node:http";
import {spawn} from "node:child_process";
import {readFile} from "node:fs/promises";
import {URL} from "node:url";
import path from "node:path";

const PORT = Number(process.env.BRIDGE_PORT || process.argv.includes("--port") ? process.argv[process.argv.indexOf("--port")+1] : 8815);
const WORKSPACE = process.env.WORKSPACE || (process.argv.includes("--workspace") ? process.argv[process.argv.indexOf("--workspace")+1] : process.cwd());
const DANGEROUS = process.argv.includes("--dangerously-skip-permissions");
const ALLOWED = (process.argv.includes("--allowed-tools")
  ? process.argv[process.argv.indexOf("--allowed-tools")+1]
  : (process.env.SD_ALLOWED_TOOLS || "sequential-thinking,memory-shared,memory,codex-bridge"));

const mapWorkspaceFile = (filePath) => {
  // expects like: /workspace/...
  if (!filePath.startsWith("/workspace")) {
    throw new Error(`Pfad muss mit /workspace beginnen: ${filePath}`);
  }
  return path.join(WORKSPACE, filePath.replace("/workspace", ""));
};

const callClaude = async (prompt) => {
  const args = ["@anthropic-ai/claude-code", "--print", "-p", prompt];
  if (ALLOWED) {
    args.push("--allow", ALLOWED);
  }
  if (DANGEROUS) {
    args.push("--dangerously-skip-permissions");
  }

  const env = {
    ...process.env,
    // map key if provided as CLAUDE_API_KEY:
    ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY || process.env.CLAUDE_API_KEY || process.env.ANTHROPIC_API_KEY || ""
  };

  const trySpawn = () =>
    new Promise((resolve, reject) => {
      const child = spawn("npx", args, {env, stdio: ["ignore", "pipe", "pipe"]});
      let out = "", err = "";
      child.stdout.on("data", (d) => { out += d.toString(); });
      child.stderr.on("data", (d) => { err += d.toString(); });
      child.on("close", (code, signal) => {
        if (code === 0) return resolve(out.trim());
        reject(new Error(`claude exited code=${code} signal=${signal} stderr=${err.trim()}`));
      });
    });

  // simple retry/backoff
  let lastErr;
  for (const backoff of [0, 500, 1500]) {
    try {
      if (backoff) await new Promise(r => setTimeout(r, backoff));
      return await trySpawn();
    } catch (e) {
      lastErr = e;
    }
  }
  throw lastErr;
};

const server = http.createServer(async (req, res) => {
  const u = new URL(req.url || "/", `http://${req.headers.host}`);
  res.setHeader("Access-Control-Allow-Origin", "*");

  if (u.pathname === "/healthz") {
    res.writeHead(200, {"content-type":"text/plain"}).end("ok");
    return;
  }

  if (u.pathname === "/run") {
    try {
      let text = "";
      const promptParam = u.searchParams.get("prompt");
      const fileParam = u.searchParams.get("file");

      if (promptParam && promptParam.trim()) {
        text = promptParam;
      } else if (fileParam) {
        const localPath = mapWorkspaceFile(fileParam);
        text = await readFile(localPath, "utf8");
      } else {
        throw new Error("Erwarte ?prompt=… oder ?file=/workspace/…");
      }

      const out = await callClaude(text);
      res.writeHead(200, {"content-type":"text/plain; charset=utf-8"}).end(out);
    } catch (e) {
      res.writeHead(400, {"content-type":"text/plain; charset=utf-8"}).end(`Bridge-Fehler: ${e.message}`);
    }
    return;
  }

  res.writeHead(404, {"content-type":"text/plain"}).end("not found");
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`[bridge] listening on http://127.0.0.1:${PORT} (workspace=${WORKSPACE})`);
});
