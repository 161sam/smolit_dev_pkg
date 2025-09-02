#!/usr/bin/env node
import { randomUUID } from 'node:crypto';
import { spawn } from 'node:child_process';
import { readFileSync, watch } from 'node:fs';
import { getSessionFile } from '../lib/sessionBus.js';

function usage() {
  console.log(`sd session new [name]\n sd session attach <id>\n sd session tail <id>`);
}

export async function cli(argv) {
  const [cmd, ...rest] = argv;
  if (cmd === 'new') {
    const id = randomUUID();
    const json = {
      session_id: id,
      export: `export SD_SESSION_ID=${id}`,
      name: rest[0],
    };
    console.log(JSON.stringify(json));
  } else if (cmd === 'attach') {
    const id = rest[0];
    if (!id) return usage();
    const shell = process.env.SHELL || '/bin/sh';
    const child = spawn(shell, { stdio: 'inherit', env: { ...process.env, SD_SESSION_ID: id } });
    child.on('exit', (c) => process.exit(c ?? 0));
  } else if (cmd === 'tail') {
    const id = rest[0];
    if (!id) return usage();
    const file = getSessionFile(id);
    try {
      process.stdout.write(readFileSync(file, 'utf8'));
    } catch {}
    watch(file, { encoding: 'utf8' }, (evt) => {
      if (evt === 'change') {
        try {
          process.stdout.write(readFileSync(file, 'utf8'));
        } catch {}
      }
    });
  } else {
    usage();
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  cli(process.argv.slice(2));
}
