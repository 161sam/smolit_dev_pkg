#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

function run(cmd, args = [], opts = {}) {
  const r = spawnSync(cmd, args, { stdio: 'pipe', encoding: 'utf8', ...opts });
  return r;
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

console.log('[test] All smoke tests passed.');

