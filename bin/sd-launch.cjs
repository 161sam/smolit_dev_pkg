#!/usr/bin/env node
// Cross-platform launcher for sd (bash on Linux/macOS, Git Bash on Windows)
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const here = __dirname;
const bashScript = path.join(here, 'sd');

function findBashOnWindows() {
  const cands = [
    process.env.GIT_BASH && path.join(process.env.GIT_BASH, 'bin', 'bash.exe'),
    'C:\\Program Files\\Git\\bin\\bash.exe',
    'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
    process.env.ProgramW6432 && path.join(process.env.ProgramW6432, 'Git', 'bin', 'bash.exe'),
    process.env.ProgramFiles && path.join(process.env.ProgramFiles, 'Git', 'bin', 'bash.exe')
  ].filter(Boolean);
  for (const cand of cands) {
    try { if (fs.existsSync(cand)) return cand; } catch {}
  }
  return null;
}

(function main(){
  const isWin = process.platform === 'win32';
  const args = process.argv.slice(2);
  if (isWin) {
    const bash = findBashOnWindows();
    if (!bash) {
      console.error('[sd] Git Bash nicht gefunden. Bitte Git for Windows installieren oder GIT_BASH setzen.');
      process.exit(1);
    }
    const child = spawn(bash, [bashScript, ...args], { stdio: 'inherit', env: process.env });
    child.on('close', (code) => process.exit(code ?? 0));
  } else {
    const child = spawn(bashScript, args, { stdio: 'inherit', env: process.env });
    child.on('close', (code) => process.exit(code ?? 0));
  }
})();
