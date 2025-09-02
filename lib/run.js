import { spawn } from 'node:child_process';
import { emit, maskEnv } from './sessionBus.js';

/**
 * Run a command with streaming stdout/stderr into session events.
 * @param {string} sessionId
 * @param {string} cmd
 * @param {string[]} args
 * @param {{cwd?:string,env?:Record<string,string>}} [opts]
 * @returns {Promise<number>}
 */
export function runWithStream(sessionId, cmd, args = [], opts = {}) {
  return new Promise((resolve, reject) => {
    const env = { ...process.env, SD_SESSION_ID: sessionId, ...(opts.env || {}) };
    const child = spawn(cmd, args, {
      cwd: opts.cwd,
      env,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    const started = Date.now();
    emit(sessionId, 'command.started', 'sd', {
      cmd,
      argv: args,
      cwd: opts.cwd || process.cwd(),
      env_masked: maskEnv(env),
    });
    function handle(type, data) {
      const str = data.toString();
      for (let i = 0; i < str.length; i += 64000) {
        const chunk = str.slice(i, i + 64000);
        emit(sessionId, type, 'sd', { chunk });
        if (type === 'command.stdout') process.stdout.write(chunk);
        else process.stderr.write(chunk);
      }
    }
    child.stdout.on('data', (d) => handle('command.stdout', d));
    child.stderr.on('data', (d) => handle('command.stderr', d));
    child.on('error', (err) => {
      emit(sessionId, 'error', 'sd', {
        where: 'runWithStream',
        message: err.message,
        stack: err.stack,
      });
      reject(err);
    });
    child.on('close', (code) => {
      emit(sessionId, 'command.finished', 'sd', {
        exit_code: code ?? 0,
        duration_ms: Date.now() - started,
      });
      resolve(code ?? 0);
    });
  });
}

