// D02 一致性：fixture 引用面防回归 — Phase 799
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const REPLAYS = 'docs/migration/replays';
const DOCS = ['docs/migration/adr', 'docs/migration/evidence', 'docs/migration/reports'];
const PROGRESS = 'docs/migration/reports/修复进展-2026-08-09.md';

const fixtures = fs.readdirSync(REPLAYS).filter((f) => f.endsWith('.mjs'));
let corpus = '';
for (const d of DOCS) {
  for (const f of fs.readdirSync(d).filter((x) => x.endsWith('.md'))) {
    corpus += fs.readFileSync(path.join(d, f), 'utf8');
  }
}
const progress = fs.readFileSync(PROGRESS, 'utf8');

const STANDALONE = [
  'd02-asset-reference-migration-cleanup.mjs',
  'd02-history-checkpoint.mjs',
  'd02-note-delete-existence-rollback.mjs',
  'd02-original-image-render-orientation.mjs',
  'd02-original-shape-partial-eraser.mjs',
  'd02-recording-completion-advance-count-bound.mjs',
  'd02-recording-playback-controller.mjs',
  'd02-system-backup-relative-path-segments.mjs',
  'd02-webdav-href-resource-identity.mjs',
];

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('no vacuous `|| true` assertions remain in fixtures',
  fixtures.filter((f) => f !== 'd02-consistency-fixture-references.mjs')
    .every((f) => !fs.readFileSync(path.join(REPLAYS, f), 'utf8')
      .includes('|'.repeat(2) + ' true')));
check('every fixture is doc-referenced or standalone-registered',
  fixtures.every((f) => corpus.includes(f) || STANDALONE.includes(f)
    || progress.includes(f)));
check('feature-note-tail pins the real collaboration ADR (0658)',
  fs.readFileSync(path.join(REPLAYS, 'd02-original-feature-note-tail.mjs'), 'utf8')
    .includes('ADR-0658-original-remote-flag-tail-failclosed.md')
  && !fs.readFileSync('docs/migration/adr/ADR-0670-original-feature-note-tail.md', 'utf8')
    .includes('ADR-0513'));
check('standalone fixtures all exist on disk',
  STANDALONE.every((f) => fs.existsSync(path.join(REPLAYS, f))));

console.log(`consistency-fixture-references replay: ${checks.length}/${checks.length} checks green`);
