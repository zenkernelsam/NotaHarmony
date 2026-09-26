// Phase 818 replay: per-package class-count closure.
// 1.0.1->1.0.3: Singular +74 / sso +2 / state +2 corroborate 817.
// 1.0.3->1.4.2: only 5 new classes inside pre-existing packages;
// data/search emptied by relocation into engine/appsearch.
import fs from 'node:fs';
import path from 'node:path';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability';

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok  ${name}`); }
  else { fail++; console.log(`FAIL  ${name} ${detail}`); }
}

function pkgFiles(v, sub = '') {
  const root = `${ROOT}/decompiled_${v}/sources/${sub}`;
  const m = new Map();
  const walk = (d) => {
    for (const f of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, f.name);
      if (f.isDirectory()) walk(p);
      else if (f.name.endsWith('.java')) {
        const rel = path.relative(root, d).replaceAll('\\', '/');
        m.set(rel, (m.get(rel) || new Set()).add(f.name));
      }
    }
  };
  if (fs.existsSync(root)) walk(root);
  return m;
}

// --- 1.0.1 -> 1.0.3 ---
const p101 = pkgFiles('1.0.1'), p103 = pkgFiles('1.0.3');
const count = (m, prefix) => [...m.entries()]
  .filter(([k]) => k === prefix || k.startsWith(prefix + '/'))
  .reduce((s, [, v]) => s + v.size, 0);
check('Singular SDK +74 classes in 1.0.3',
  count(p101, 'com/singular') === 0 && count(p103, 'com/singular') === 74,
  `${count(p101, 'com/singular')}->${count(p103, 'com/singular')}`);
check('sso package arrives in 1.0.3 (Google Credential Manager)',
  !p101.has('sso') && p103.get('sso')?.has('a.java') &&
  p103.get('sso')?.has('GoogleCredentialException.java'));
check('state pkg gains ExportFileProvider+ExportSweepWorker',
  [...(p103.get('com/gingerlabs/notability/data/library/state') || [])]
    .filter(f => f.startsWith('Export')).length === 2);

// --- 1.0.3 -> 1.4.2 inside com/gingerlabs ---
const g103 = pkgFiles('1.0.3', 'com/gingerlabs');
const g142 = pkgFiles('1.4.2', 'com/gingerlabs');
const allPk = new Set([...g103.keys(), ...g142.keys()]);
const grewPre = [], shrank = [];
for (const k of allPk) {
  const a = g103.get(k)?.size || 0, b = g142.get(k)?.size || 0;
  if (b > a && a > 0) grewPre.push([k, a, b]);
  if (b < a) shrank.push([k, a, b]);
}
check('5 pre-existing packages gained +1 each',
  grewPre.length === 5 && grewPre.every(([, a, b]) => b === a + 1),
  JSON.stringify(grewPre));
const newClasses = [];
for (const [k] of grewPre) {
  for (const f of g142.get(k)) if (!g103.get(k).has(f)) newClasses.push(f);
}
check('exactly 5 new classes inside pre-existing packages',
  newClasses.length === 5, newClasses.join(','));
check('new classes are registered-cluster members',
  newClasses.includes('NoteOpsGoneException.java') &&
  newClasses.includes('HandwritingEngineUnavailableException.java') &&
  newClasses.includes('ApiGatedFirebaseInitProvider.java') &&
  newClasses.some(f => f.startsWith('FirebaseLogger')));

check('only shrunk pkg = data/search (relocation, not removal)',
  shrank.length === 1 && shrank[0][0] === 'notability/data/search' &&
  shrank[0][1] === 2 && shrank[0][2] === 0);
check('SearchResult relocated into data/search/engine/appsearch',
  (g142.get('notability/data/search/engine/appsearch') || new Set())
    .has('SearchResult.java'));

// Package-set identity check for 1.0.1 -> 1.0.3 (49 = 49).
const set1 = new Set(p101.keys()), set3 = new Set(p103.keys());
const pAdd = [...set3].filter(k => !set1.has(k));
const pRem = [...set1].filter(k => !set3.has(k));
check('1.0.1->1.0.3 com.gingerlabs pkg sets identical (49/49)',
  count(p101, 'com/gingerlabs') > 0 &&
  pAdd.filter(k => k.startsWith('com/gingerlabs')).length === 0 &&
  pRem.filter(k => k.startsWith('com/gingerlabs')).length === 0 &&
  [...set3].filter(k => k.startsWith('com/gingerlabs')).length === 49);

console.log(`\npackage-class-closure replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
