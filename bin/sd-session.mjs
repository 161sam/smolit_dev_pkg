#!/usr/bin/env node
// sd session <subcommand>
import process from "node:process";
import { listSessions } from "../lib/sessionBus.js";

const [sub, ...rest] = process.argv.slice(2);

function usage() {
  console.log(`Usage:
  sd session list            # recent sessions
  sd session help            # this help
`);
}

if (!sub || sub === "help" || sub === "--help" || sub === "-h") {
  usage();
  process.exit(0);
}

if (sub === "list") {
  const rows = listSessions(200);
  if (!rows.length) {
    console.log("No sessions found.");
    process.exit(0);
  }
  const pad = (s, n) => String(s || "").padEnd(n, " ");
  const W = { id: 36, name: 22, cwd: 36, ts: 20 };
  console.log(
    pad("SESSION_ID", W.id) + "  " +
    pad("NAME", W.name) + "  " +
    pad("CWD", W.cwd) + "  " +
    pad("CREATED", W.ts)
  );
  for (const s of rows) {
    console.log(
      pad(s.session_id, W.id) + "  " +
      pad(s.name, W.name) + "  " +
      pad(s.cwd, W.cwd) + "  " +
      pad(s.created_at, W.ts)
    );
  }
  process.exit(0);
}

usage();
process.exit(1);
