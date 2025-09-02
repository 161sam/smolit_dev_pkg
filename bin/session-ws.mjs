#!/usr/bin/env node
import { createServer } from 'node:http';
import { WebSocketServer } from 'ws';
import { appendFileSync, readFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { getSessionFile } from '../lib/sessionBus.js';

const server = createServer();
const wss = new WebSocketServer({ server });
const subs = new Map();

function ensure(file) {
  mkdirSync(dirname(file), { recursive: true });
}

wss.on('connection', (ws) => {
  ws.on('message', (msg) => {
    let data;
    try {
      data = JSON.parse(msg.toString());
    } catch {
      return;
    }
    if (data.op === 'subscribe' && data.session_id) {
      const sid = data.session_id;
      if (!subs.has(sid)) subs.set(sid, new Set());
      subs.get(sid).add(ws);
      const file = getSessionFile(sid);
      if (existsSync(file)) {
        const lines = readFileSync(file, 'utf8').trim().split(/\n+/).filter(Boolean);
        for (const line of lines) ws.send(line);
      }
      ws.on('close', () => subs.get(sid)?.delete(ws));
    } else if (data.op === 'publish' && data.session_id && data.event) {
      const sid = data.session_id;
      const evt = data.event;
      const file = getSessionFile(sid);
      try {
        ensure(file);
        appendFileSync(file, JSON.stringify(evt) + '\n');
      } catch {
        /* ignore */
      }
      const json = JSON.stringify(evt);
      const set = subs.get(sid);
      if (set) {
        for (const c of set) {
          try {
            c.send(json);
          } catch {
            /* ignore */
          }
        }
      }
    }
  });
});

server.listen(52321, '127.0.0.1', () => {
  console.log('[session-ws] ready');
});
