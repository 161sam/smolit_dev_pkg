#!/usr/bin/env node
import http from "node:http";
import { spawn } from "node:child_process";
import { readFile } from "node:fs/promises";
import { URL } from "node:url";
import path from "node:path";

/* ---------- small arg helper ---------- */
const arg = (flag, fallback) => {
  const i = process.argv.indexOf(flag);
  return i !== -1 ? process.argv[i + 1] : fallback;
};

/* ---------- config ---------- */
const PORT = Number(process.env.BRIDGE_PORT || arg("--port", 8815));
const WORKSPACE = process.env.WORKSPACE || arg("--workspace", process.cwd());
const DANGEROUS = process.argv.includes("--dangerously-skip-permissions");
const ALLOWED =
  arg("--allowed-tools", process.env.SD_ALLOWED_TOOLS) ||
  "sequential-thinking,memory-shared,memory,codex-bridge";

/* ---------- helpers ---------- */
const mapWorkspaceFile = (filePath) => {
  // normalize posix-style for container-like paths
  const norm = path.posix.normalize(filePath);
  if (!norm.startsWith("/workspace")) {
    throw new Error(`Pfad muss mit /workspace beginnen: ${filePath}`);
  }
  // trim the "/workspace" prefix only (both "/workspace" and "/workspace/...").
  const rel = norm.slice("/workspace".length); // may be "" or like "/foo/bar.txt"
  const hostPath = path.resolve(path.join(WORKSPACE, rel));
  const wsRoot = path.resolve(WORKSPACE);
  if (!hostPath.startsWith(wsRoot)) {
    throw new Error("Pfad außerhalb des WORKSPACE");
  }
  return hostPath;
};

const readBody = (req, limit = 1_000_000) =>
  new Promise((resolve, reject) => {
    let total = 0;
    const chunks = [];
    req.on("data", (c) => {
      total += c.length;
      if (total > limit) {
        const e = new Error("Payload too large");
        e.status = 413;
        req.destroy(e);
        reject(e);
      } else {
        chunks.push(c);
      }
    });
    req.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    req.on("error", reject);
  });

/* ---------- claude launcher (with flag fallback) ---------- */
const callClaude = async (prompt) => {
  const env = {
    ...process.env,
    ANTHROPIC_API_KEY:
      process.env.ANTHROPIC_API_KEY || process.env.CLAUDE_API_KEY || "",
  };

  const run = (useFlags = true) =>
    new Promise((resolve, reject) => {
      const args = ["@anthropic-ai/claude-code", "--print", "-p", prompt];
      if (useFlags) {
        if (ALLOWED) args.push("--allowed-tools", ALLOWED);
        if (DANGEROUS) args.push("--dangerously-skip-permissions");
      }
      const child = spawn("npx", args, { env, stdio: ["ignore", "pipe", "pipe"] });
      let out = "",
        err = "";
      child.stdout.on("data", (d) => (out += d));
      child.stderr.on("data", (d) => (err += d));
      child.on("error", reject);
      child.on("close", (code, signal) => {
        if (code !== 0)
          return reject(
            new Error(
              `claude exited code=${code} signal=${signal} stderr=${err.trim()}`
            )
          );
        resolve(out);
      });
    });

  try {
    return await run(true); // first try with flags
  } catch (e) {
    if (String(e).match(/unknown option|Unknown argument|did you mean/i)) {
      console.warn(
        "[bridge] CLI kennt --allowed-tools/--dangerously-skip-permissions nicht – retry ohne Flags."
      );
      return await run(false); // retry without flags
    }
    throw e;
  }
};

/* ---------- http server ---------- */
const server = http.createServer(async (req, res) => {
  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") {
    res.writeHead(204).end();
    return;
  }

  const u = new URL(req.url || "/", `http://${req.headers.host}`);
  try {
    // health/version
    if (u.pathname === "/healthz") {
      res.writeHead(200, { "content-type": "text/plain" }).end("ok");
      return;
    }
    if (u.pathname === "/version") {
      res
        .writeHead(200, { "content-type": "application/json" })
        .end(JSON.stringify({ version: process.env.npm_package_version || "dev" }));
      return;
    }

    // unify handlers
    const handleRun = async () => {
      let text = "";
      if (req.method === "POST") {
        const ct = (req.headers["content-type"] || "").toLowerCase();
        const body = await readBody(req);
        if (ct.includes("application/json")) {
          const json = JSON.parse(body || "{}");
          if (json.prompt) text = String(json.prompt);
          else if (json.file) text = await readFile(mapWorkspaceFile(String(json.file)), "utf8");
          else if (json.path) text = await readFile(mapWorkspaceFile(String(json.path)), "utf8");
        } else {
          // raw text fallback
          text = body;
        }
      } else {
        const p = u.searchParams.get("prompt");
        const f = u.searchParams.get("file");
        const qpath = u.searchParams.get("path");
        if (p && p.trim()) text = p;
        else if (f) text = await readFile(mapWorkspaceFile(f), "utf8");
        else if (qpath) text = await readFile(mapWorkspaceFile(qpath), "utf8");
      }

      if (!text || !text.trim()) {
        const err = new Error("Kein 'prompt', 'file' oder 'path' angegeben.");
        err.status = 400;
        throw err;
      }

      const out = await callClaude(text);
      res
        .writeHead(200, { "content-type": "text/plain; charset=utf-8" })
        .end(out);
    };

    if (u.pathname === "/run" || u.pathname === "/run-file") {
      await handleRun();
      return;
    }

    res.writeHead(404, { "content-type": "text/plain" }).end("not found");
  } catch (e) {
    res
      .writeHead(e.status || 400, { "content-type": "text/plain; charset=utf-8" })
      .end(`Bridge-Fehler: ${e.message}`);
  }
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(
    `[bridge] listening on http://127.0.0.1:${PORT} (workspace=${WORKSPACE})`
  );
});
