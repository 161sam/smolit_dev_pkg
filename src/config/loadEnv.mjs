// Minimal environment loader without external deps
export function loadEnv() {
  const bool = (v) => String(v).toLowerCase() === 'true' || v === '1';
  const num = (v, d) => (v != null && v !== '' ? Number(v) : d);
  const str = (v, d) => (v != null && v !== '' ? String(v) : d);

  return {
    workspace: str(process.env.WORKSPACE, process.cwd()),
    ports: {
      oh: num(process.env.OH_PORT, 3311),
      seq: num(process.env.SEQ_PORT, 8811),
      mem: num(process.env.MEM_PORT, 8812),
      bridge: num(process.env.BRIDGE_PORT, 8815),
    },
    lmBaseUrl: str(process.env.LM_BASE_URL, 'http://127.0.0.1:1234/v1'),
    allowedTools: str(process.env.SD_ALLOWED_TOOLS, 'sequential-thinking,memory-shared,memory,codex-bridge'),
    api: {
      anthropic: str(process.env.ANTHROPIC_API_KEY || process.env.CLAUDE_API_KEY, ''),
      openai: str(process.env.OPENAI_API_KEY, ''),
    },
    ci: bool(process.env.CI),
    skipPostinstall: bool(process.env.NO_POSTINSTALL) || bool(process.env.SKIP_POSTINSTALL),
  };
}

