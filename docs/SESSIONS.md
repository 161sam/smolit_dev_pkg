# Session Event Bus

The session system records command and LLM activity for every `sd` run. Each session has a
unique `session_id` and events are persisted to a JSONL file and optionally broadcast via a
WebSocket hub.

## Files

Events are written to `~/.sd/sessions/<session_id>.jsonl` unless `--jsonl` is used or
`SD_SESSION_FILE`/`SD_SESSIONS_DIR` are set.

## Environment

- `SD_SESSION_ID` – current session identifier
- `SD_SESSIONS_DIR` – base directory for session files
- `SD_SESSION_FILE` – full path override for session file
- `SD_WS_URL` – WebSocket hub URL (default `ws://127.0.0.1:52321`)
- `SD_WS_DISABLED=1` – disable WebSocket broadcasting

## CLI

```
sd [--session <id>] [--session-name <name>] [--no-ws] [--jsonl <path>] <cmd> [args]
```

Session helper commands:

```
sd session new [name]
sd session attach <id>
sd session tail <id>
```

## WebSocket Hub

Start the hub separately:

```
node bin/session-ws.mjs
```

Clients subscribe or publish using JSON messages. Every publish is appended to the session
file and broadcast to subscribers.

## GUI Integration

```
import { connectSession } from '../gui/sessionClient.js';
connectSession(sessionId, {
  onEvent: (evt) => renderEventInChat(evt)
});
```

## Event Types

Events use the schema version `v:1` and include types such as `session.started`,
`command.stdout`, `llm.message` and more. Sensitive environment variables ending in
`KEY`, `TOKEN`, `SECRET` or `PASSWORD` are masked.

