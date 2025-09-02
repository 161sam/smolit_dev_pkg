// lib/sessionBus.js
// Session Event Bus: JSONL persistence + optional WebSocket broadcast
// Also provides session registry & default name generation.

import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import crypto from "node:crypto";

const HOME = os.homedir();
const SD_DIR = path.join(HOME, ".sd");
const SESS_DIR = path.join(SD_DIR, "sessions");
const INDEX_FILE = path.join(SESS_DIR, "index.json");

fs.mkdirSync(SESS_DIR, { recursive: true });

// --- Registry helpers ----------------------------------------------------

function readIndex() {
  try {
    const s = fs.readFileSync(INDEX_FILE, "utf8");
    const j = JSON.parse(s);
    if (j && typeof j === "object" && Array.isArray(j.sessions)) return j;
  } catch {}
  return { version: 1, sessions: [] };
}

function writeIndex(idx) {
  try {
    fs.writeFileSync(INDEX_FILE, JSON.stringify(idx, null, 2), "utf8");
  } catch {}
}

/**
 * Register session metadata for quick lookup in `sd session list`.
 */
export function registerSession(sessionId, name, cwd) {
  const idx = readIndex();
  const ts = new Date().toISOString();
  // If exists, update; else push
  const pos = idx.sessions.findIndex((s) => s.session_id === sessionId);
  const row = {
    session_id: sessionId,
    name,
    cwd,
    created_at: ts,
    updated_at: ts,
  };
  if (pos >= 0) {
    idx.sessions[pos] = { ...idx.sessions[pos], ...row, updated_at: ts };
  } else {
    idx.sessions.unshift(row);
    // cap list to avoid bloat
    if (idx.sessions.length > 1000) idx.sessions.length = 1000;
  }
  writeIndex(idx);
}

/**
 * Return recent session registry (array).
 */
export function listSessions(limit = 50) {
  const idx = readIndex();
  return idx.sessions.slice(0, limit);
}

// --- Session name helpers ------------------------------------------------

function slugify(s) {
  return String(s)
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-zA-Z0-9._-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40) || "workspace";
}

/**
 * Create a short base36 id like "x7k2b".
 */
function shortId() {
  return crypto.randomBytes(4).toString("base64url").replace(/[^a-zA-Z0-9]/g, "").toLowerCase().slice(0, 5);
}

/**
 * Derive a sensible default session name from CWD.
 * Example: /home/saschi/NeuesProjekt -> "NeuesProjekt-x7k2b"
 */
export function getDefaultSessionName(cwd = process.cwd()) {
  const base = slugify(path.basename(cwd || "workspace")) || "workspace";
  return `${base}-${shortId()}`;
}

// --- JSONL file helpers --------------------------------------------------

export function getSessionFile(sessionId) {
  // allow override via env (tests)
  const overrideDir = process.env.SD_JSONL_OVERRIDE ? path.resolve(process.env.SD_JSONL_OVERRIDE) : SESS_DIR;
  try { fs.mkdirSync(overrideDir, { recursive: true }); } catch {}
  return path.join(overrideDir, `${sessionId}.jsonl`);
}

// --- WebSocket (optional) ------------------------------------------------

let ws = null;
function ensureWS() {
  if (process.env.SD_WS_DISABLED === "1") return null;
  try {
    if (ws && ws.readyState === 1) return ws;
    const url = process.env.SD_WS_URL || "ws://127.0.0.1:52321";
    const { WebSocket } = requireOrImportWS();
    ws = new WebSocket(url);
    return ws;
  } catch {
    return null;
  }
}

function requireOrImportWS() {
  // Lazy require to avoid hard dependency at runtime if not installed
  try {
    // eslint-disable-next-line global-require
    const WebSocket = require("ws");
    return { WebSocket };
  } catch {
    // dynamic import fallback (ESM environments)
    // eslint-disable-next-line no-new-func
    const req = new Function("m", "return import(m)");
    // Not awaited: caller will attempt again later harmlessly
    // We return a dummy to avoid crashes.
    return { WebSocket: class DummyWS { constructor() { this.readyState = 3; } send(){} } };
  }
}

// --- ENV masking ---------------------------------------------------------

function maskEnv(env) {
  const out = {};
  const re = /(KEY|TOKEN|SECRET|PASSWORD)$/i;
  for (const [k, v] of Object.entries(env || {})) {
    if (re.test(k)) out[k] = "****";
    else out[k] = typeof v === "string" ? v : String(v);
  }
  return out;
}

// --- Session ID ----------------------------------------------------------

export function getSessionId() {
  return process.env.SD_SESSION_ID || crypto.randomUUID();
}

// --- Emit ---------------------------------------------------------------

/**
 * Append event to JSONL (and broadcast via WS if available).
 */
export function emit(sessionId, type, source, payload) {
  const evt = {
    v: 1,
    ts: new Date().toISOString(),
    type,
    session_id: sessionId,
    source,
    payload: payload ?? {},
  };
  const line = JSON.stringify(evt) + "\n";
  try {
    fs.appendFileSync(getSessionFile(sessionId), line, "utf8");
  } catch {}
  try {
    const sock = ensureWS();
    if (sock && sock.readyState === 1) sock.send(line);
  } catch {}
  return evt;
}

/**
 * Helper to wrap execution blocks and emit errors if they occur.
 */
export async function withSession(sessionId, fn) {
  try {
    return await fn(emit);
  } catch (err) {
    emit(sessionId, "error", "sd", {
      where: "withSession",
      message: String(err?.message || err),
      stack: String(err?.stack || ""),
    });
    throw err;
  }
}

// --- public utils --------------------------------------------------------

export function buildCommandStartedPayload(cmd, argv, cwd, envObj) {
  return {
    cmd,
    argv,
    cwd,
    env_masked: maskEnv(envObj || process.env),
  };
}
