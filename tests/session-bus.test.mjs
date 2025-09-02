import { getSessionId, emit, getSessionFile } from '../lib/sessionBus.js';
import { existsSync, readFileSync, rmSync } from 'node:fs';
import assert from 'node:assert/strict';

const sessionId = getSessionId();
process.env.SD_SESSION_FILE = `./tests/tmp-${sessionId}.jsonl`;
emit(sessionId, 'status.update', 'system', { key: 't', value: 1 });
const file = getSessionFile(sessionId);
assert.ok(existsSync(file), 'session file exists');
const line = readFileSync(file, 'utf8').trim();
const evt = JSON.parse(line);
assert.equal(evt.type, 'status.update');
rmSync(file);
console.log('session-bus test ok');
