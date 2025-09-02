import { appendFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { randomUUID } from 'node:crypto';
import { WebSocket } from 'ws';

/**
 * Resolve or generate a session id.
 * @returns {string}
 */
export function getSessionId() {
  return process.env.SD_SESSION_ID || randomUUID();
}

/**
 * Base directory for session logs.
 * Can be overridden via SD_SESSIONS_DIR.
 */
const sessionsDir =
  process.env.SD_SESSIONS_DIR || join(process.env.HOME || process.cwd(), '.sd', 'sessions');

/**
 * Resolve path to a session JSONL file.
 * SD_SESSION_FILE overrides the full path.
 * @param {string} sessionId
 * @returns {string}
 */
export function getSessionFile(sessionId) {
  if (process.env.SD_SESSION_FILE) return process.env.SD_SESSION_FILE;
  return join(sessionsDir, `${sessionId}.jsonl`);
}

let ws;

function getWs() {
  if (process.env.SD_WS_DISABLED === '1') return null;
  if (ws && ws.readyState <= 1) return ws;
  const url = process.env.SD_WS_URL || 'ws://127.0.0.1:52321';
  try {
    ws = new WebSocket(url);
    ws.on('error', () => {});
  } catch {
    ws = null;
  }
  return ws;
}

function ensureDir(file) {
  mkdirSync(dirname(file), { recursive: true });
}

/**
 * Mask environment values with sensitive suffixes.
 * @param {Record<string,string>} env
 */
export function maskEnv(env) {
  const masked = {};
  const re = /(KEY|TOKEN|SECRET|PASSWORD)$/i;
  for (const [k, v] of Object.entries(env)) {
    masked[k] = re.test(k) ? '****' : v;
  }
  return masked;
}

/**
 * Emit an event to JSONL file and optional WS hub.
 * @param {string} sessionId
 * @param {string} type
 * @param {string} source
 * @param {Record<string,unknown>} payload
 */
export function emit(sessionId, type, source, payload = {}) {
  const evt = {
    v: 1,
    ts: new Date().toISOString(),
    type,
    session_id: sessionId,
    source,
    payload,
  };
  const file = getSessionFile(sessionId);
  try {
    ensureDir(file);
    appendFileSync(file, JSON.stringify(evt) + '\n');
  } catch {
    // ignore
  }
  const socket = getWs();
  if (socket && socket.readyState === WebSocket.OPEN) {
    try {
      socket.send(
        JSON.stringify({ op: 'publish', session_id: sessionId, event: evt })
      );
    } catch {
      // ignore
    }
  }
  return evt;
}

/**
 * Execute a function within session context, catching errors.
 * @param {string} sessionId
 * @param {(emit:(type:string,source:string,payload:Record<string,unknown>)=>void)=>any} fn
 */
export function withSession(sessionId, fn) {
  try {
    return fn((type, source, payload) => emit(sessionId, type, source, payload));
  } catch (err) {
    emit(sessionId, 'error', 'sd', {
      where: 'withSession',
      message: err instanceof Error ? err.message : String(err),
      stack: err instanceof Error ? err.stack : undefined,
    });
    throw err;
  }
}

