#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

function run(cmd, args = [], opts = {}) {
  return spawnSync(cmd, args, { stdio: 'pipe', encoding: 'utf8', ...opts });
}

function okExit(res, name) {
  if (res.status !== 0) {
    console.error(`[test] ${name} failed:`, res.status, res.stderr || res.stdout);
    process.exit(1);
  }
}

// 1) Node version
console.log('[test] Node version:', process.version);
assert.ok(Number(process.versions.node.split('.')[0]) >= 18, 'Node >= 18 required');

// 2) postinstall dry-run should not error
const pi = run('node', ['bin/postinstall.mjs', '--dry-run'], { env: { ...process.env, CI: '1' } });
okExit(pi, 'postinstall --dry-run');

// 3) sd --help
const help = run('./bin/sd', ['--help'], { env: process.env });
okExit(help, 'sd --help');
assert.ok(help.stdout.includes('Usage') || help.stdout.length > 0, 'sd --help output');

// 4) package.json bin mapping
const pkg = JSON.parse(readFileSync('package.json', 'utf8'));
assert.equal(pkg.bin.sd, 'bin/sd-launch.cjs', 'bin mapping points to sd-launch.cjs');

// 5) Detailed tests
for (const t of [
  'tests/session-bus.test.mjs',
  'tests/run-stream.test.mjs',
  'tests/ws-hub.test.mjs',
]) {
  const r = run('node', [t], { env: { ...process.env } });
  okExit(r, t);
}

console.log('[test] All smoke tests passed.');
