import { spawn } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { WebSocket } from 'ws';
import { mkdirSync, rmSync } from 'node:fs';
import assert from 'node:assert/strict';

const tmpDir = './tests/tmp-ws';
mkdirSync(tmpDir, { recursive: true });
process.env.SD_SESSIONS_DIR = tmpDir;
const { getSessionFile } = await import('../lib/sessionBus.js');

const server = spawn('node', ['bin/session-ws.mjs'], {
  env: { ...process.env },
  stdio: ['ignore', 'pipe', 'inherit'],
});

await new Promise((res) => {
  server.stdout.on('data', (d) => {
    if (d.toString().includes('ready')) res();
  });
});

const sessionId = randomUUID();
const url = 'ws://127.0.0.1:52321';
const ws1 = new WebSocket(url);
await new Promise((r) => ws1.on('open', r));
const events1 = [];
ws1.on('message', (m) => events1.push(JSON.parse(m.toString())));
ws1.send(JSON.stringify({ op: 'subscribe', session_id: sessionId }));
const evt = {
  v: 1,
  ts: new Date().toISOString(),
  type: 'status.update',
  session_id: sessionId,
  source: 'sd',
  payload: { key: 'a', value: 1 },
};
ws1.send(JSON.stringify({ op: 'publish', session_id: sessionId, event: evt }));
await new Promise((r) => setTimeout(r, 200));
assert.equal(events1.length, 1);
const ws2 = new WebSocket(url);
await new Promise((r) => ws2.on('open', r));
const events2 = [];
ws2.on('message', (m) => events2.push(JSON.parse(m.toString())));
ws2.send(JSON.stringify({ op: 'subscribe', session_id: sessionId }));
await new Promise((r) => setTimeout(r, 200));
assert.equal(events2.length, 1);
ws1.close();
ws2.close();
server.kill();
rmSync(getSessionFile(sessionId));
console.log('ws-hub test ok');
