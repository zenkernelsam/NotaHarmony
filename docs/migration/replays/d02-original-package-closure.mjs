// D02 原版 1.4.2 com.gingerlabs 包级归属收尾 — Phase 793
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const D103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources';
const D142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources';

const dirsOf = (root) => {
  const out = [];
  const walk = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      if (!e.isDirectory()) continue;
      const p = path.join(d, e.name);
      out.push(p.slice(root.length + 1).split(path.sep).join('/'));
      walk(p);
    }
  };
  walk(root);
  return new Set(out);
};

const set103 = dirsOf(D103);
const set142 = dirsOf(D142);
const newPkgs = [...set142].filter((d) => !set103.has(d) && d.startsWith('com/gingerlabs'));

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const EXPECTED = [
  'com/gingerlabs/notability/app/demo',
  'com/gingerlabs/notability/core/model/snapshot',
  'com/gingerlabs/notability/core/workmanager',
  'com/gingerlabs/notability/data/backgroundwork',
  'com/gingerlabs/notability/data/calendar',
  'com/gingerlabs/notability/data/calendar/database',
  'com/gingerlabs/notability/data/gallery',
  'com/gingerlabs/notability/data/gallery/outbox',
  'com/gingerlabs/notability/data/handwritingrecognition/hwr',
  'com/gingerlabs/notability/data/handwritingrecognition/myscript',
  'com/gingerlabs/notability/data/learn/syllabus',
  'com/gingerlabs/notability/data/library/state/notelimit',
  'com/gingerlabs/notability/data/loginstate',
  'com/gingerlabs/notability/data/search/engine/appsearch',
  'com/gingerlabs/notability/data/settings/sync',
  'com/gingerlabs/notability/data/templates',
  'com/gingerlabs/notability/data/templates/database',
  'com/gingerlabs/notability/data/templates/sync',
  'com/gingerlabs/notability/data/user',
  'com/gingerlabs/notability/domain/maintenance',
  'com/gingerlabs/notability/feature/note/stickers',
  'com/gingerlabs/notability/feature/note/stickers/packs',
];

check('exactly 22 new com.gingerlabs packages in 1.4.2', newPkgs.length === 22);
check('new-package set matches the registered attribution table',
  EXPECTED.every((p) => newPkgs.includes(p))
  && newPkgs.every((p) => EXPECTED.includes(p)));
check('loginstate = sealed PostCommitLoginException + 2 subclasses',
  fs.readFileSync(path.join(D142,
    'com/gingerlabs/notability/data/loginstate/PostCommitLoginException.java'), 'utf8')
    .includes('PostCommitLoginException extends IOException'));
check('domain/maintenance worker is a CoroutineWorker (775 cluster)',
  fs.readFileSync(path.join(D142,
    'com/gingerlabs/notability/domain/maintenance/BackgroundMaintenanceWorker.java'), 'utf8')
    .includes('extends CoroutineWorker'));
check('myscript pkg = engine-feed exception only (768 cluster)',
  fs.readdirSync(path.join(D142,
    'com/gingerlabs/notability/data/handwritingrecognition/myscript'))
    .includes('MyScriptEngineFeedException.java'));
check('data/user = passkey/SSO exception family (771 cluster)',
  ['MalformedPasskeyPayloadException.java', 'NullAuthTokenException.java',
    'PasskeyActivityGoneException.java', 'SsoVerificationException.java']
    .every((f) => fs.readdirSync(path.join(D142,
      'com/gingerlabs/notability/data/user')).includes(f)));

console.log(`package-closure replay: ${checks.length}/${checks.length} checks green`);
