# Security Policy

- Report vulnerabilities via GitHub Issues or email (see repo).
- Do not include secrets in issues or logs.
- `postinstall` performs only local, idempotent setup and respects `CI`, `NO_POSTINSTALL`, `SKIP_POSTINSTALL`.
- The HTTP bridge shell-spawns `npx @anthropic-ai/claude-code` on demand; restrict allowed tools via `SD_ALLOWED_TOOLS` and avoid `--dangerously-skip-permissions` in production.

