# Contributing

- Use Node >= 18.18
- Install dev deps: `npm install`
- Lint: `npm run lint`
- Format: `npm run format`
- Tests: `npm test`
- CI runs on Node 18.x and 20.x (see `.github/workflows/ci.yml`).

## Development

- Avoid network operations in `postinstall`. It must be idempotent and skip in CI.
- Keep CLI help (`sd --help`) up to date when adding commands.
- Prefer ESM for new modules; CommonJS only where required (launcher).

