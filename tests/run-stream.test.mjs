import { getSessionId, getSessionFile } from '../lib/sessionBus.js';
import { runWithStream } from '../lib/run.js';
import { readFileSync, rmSync } from 'node:fs';
import assert from 'node:assert/strict';

const sessionId = getSessionId();
process.env.SD_SESSION_FILE = `./tests/tmp-run-${sessionId}.jsonl`;
const code = await runWithStream(sessionId, 'node', [
  '-e',
  "process.stdout.write('out'); process.stderr.write('err');",
]);
assert.equal(code, 0);
const file = getSessionFile(sessionId);
const lines = readFileSync(file, 'utf8').trim().split(/\n+/);
rmSync(file);
const types = lines.map((l) => JSON.parse(l).type);
assert.deepEqual(types, [
  'command.started',
  'command.stdout',
  'command.stderr',
  'command.finished',
]);
console.log('run-stream test ok');
