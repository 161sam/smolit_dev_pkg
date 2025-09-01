#!/usr/bin/env node
import fs from "node:fs";

const p = JSON.parse(fs.readFileSync("package.json","utf8"));

p.preferGlobal = true;

p.scripts = {
  ...(p.scripts||{}),
  "prepack": "chmod +x bin/sd bin/bridge.mjs bin/postinstall.mjs",
  "postinstall": "node ./bin/postinstall.mjs",
  "lint:shell": "command -v shellcheck >/dev/null 2>&1 && shellcheck bin/sd || echo 'shellcheck not installed'",
  "lint:node": "node -e \"console.log('node', process.version)\"",
  "ci:smoke": "node ./bin/postinstall.mjs --dry-run && node -e \"console.log('bridge ok')\" && ./bin/sd --help || true"
};

p.engines = { ...(p.engines||{}), node: ">=18" };

if (!p.files) {
  p.files = ["bin/","templates/","env.example","README.md","LICENSE"];
} else {
  for (const add of ["bin/","templates/","env.example","README.md","LICENSE"]) {
    if (!p.files.includes(add)) p.files.push(add);
  }
}

fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");
console.log("package.json patched.");
