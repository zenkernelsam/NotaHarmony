// Phase 813 replay: assets/ content-level diff + xxhdpi split closure.
// Pins the 5 shared-name content changes (incl. MyScript SetWordListSize
// tuning), the added-dir cluster mapping, and the density-split delta.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability';

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok  ${name}`); }
  else { fail++; console.log(`FAIL  ${name} ${detail}`); }
}

function hashTree(dir) {
  const out = new Map();
  const walk = (d) => {
    for (const f of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, f.name);
      if (f.isDirectory()) walk(p);
      else out.set(path.relative(dir, p).replaceAll('\\', '/'),
        crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex'));
    }
  };
  walk(dir);
  return out;
}

const a = hashTree(`${ROOT}/decompiled_1.0.3/resources/assets`);
const b = hashTree(`${ROOT}/decompiled_1.4.2/resources/assets`);

check('assets counts 115 -> 576', a.size === 115 && b.size === 576,
  `${a.size}/${b.size}`);

// Added files group into already-registered clusters.
const added = [...b.keys()].filter(k => !a.has(k));
const groups = {};
for (const k of added) groups[k.split('/')[0]] = (groups[k.split('/')[0]] || 0) + 1;
check('465 added files in 5 registered dirs',
  added.length === 465 &&
  groups.papertemplates === 446 && groups.brushpacks === 5 &&
  groups.covers === 10 && groups.planners === 2 && groups.spellcheck === 2,
  JSON.stringify(groups));

const removed = [...a.keys()].filter(k => !b.has(k));
check('4 removed = MyScript lite resources',
  removed.length === 4 && removed.every(k => k.includes('lite')));

// Shared-name content changes: exactly 5.
const changed = [...a.keys()].filter(k => b.has(k) && a.get(k) !== b.get(k));
check('exactly 5 shared assets changed', changed.length === 5,
  changed.join(','));
check('changed set = conf + dexopt + MyScript res',
  changed.includes('conf/en_US.conf') &&
  changed.includes('dexopt/baseline.prof') &&
  changed.includes('dexopt/baseline.profm') &&
  changed.includes('resources/document_layout/dl-raw-content.res') &&
  changed.includes('resources/math/math-sr.res'));

// The MyScript tuning delta: SetWordListSize 5 -> 1.
const confA = fs.readFileSync(
  `${ROOT}/decompiled_1.0.3/resources/assets/conf/en_US.conf`, 'utf8');
const confB = fs.readFileSync(
  `${ROOT}/decompiled_1.4.2/resources/assets/conf/en_US.conf`, 'utf8');
check('en_US.conf: SetWordListSize 5 -> 1',
  (confA.match(/SetWordListSize 5/g) || []).length === 2 &&
  (confB.match(/SetWordListSize 1/g) || []).length === 2 &&
  !confB.includes('SetWordListSize 5'));

// xxhdpi split: inventory delta from nested apk member.
const XAPK = {
  '1.0.3': `${ROOT}/Notability_1.0.3/Notability_+AI+Note+Workspace_1.0.3_APKPure.xapk`,
  '1.4.2': `${ROOT}/Notability_1.4.2/Notability%3A+AI+Note+Workspace_1.4.2_apkcombo.com.xapk`,
};
function cdEntries(buf) {
  const eocd = buf.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  const count = buf.readUInt16LE(eocd + 10);
  let off = buf.readUInt32LE(eocd + 16);
  const out = [];
  for (let i = 0; i < count; i++) {
    const nlen = buf.readUInt16LE(off + 28);
    const xlen = buf.readUInt16LE(off + 30);
    const cmlen = buf.readUInt16LE(off + 32);
    out.push({
      name: buf.toString('utf8', off + 46, off + 46 + nlen),
      method: buf.readUInt16LE(off + 10),
      csize: buf.readUInt32LE(off + 20),
      lho: buf.readUInt32LE(off + 42),
    });
    off += 46 + nlen + xlen + cmlen;
  }
  return out;
}
function member(buf, e) {
  const nlen = buf.readUInt16LE(e.lho + 26);
  const xlen = buf.readUInt16LE(e.lho + 28);
  const start = e.lho + 30 + nlen + xlen;
  const raw = buf.subarray(start, start + e.csize);
  return e.method === 8 ? zlib.inflateRawSync(raw) : raw;
}
function xxhdpiNames(v) {
  const buf = fs.readFileSync(XAPK[v]);
  const e = cdEntries(buf).find(x => x.name === 'config.xxhdpi.apk');
  return cdEntries(member(buf, e)).map(c => c.name)
    .filter(n => n.endsWith('.png') || n.endsWith('.webp'));
}
const xa = xxhdpiNames('1.0.3'), xb = xxhdpiNames('1.4.2');
const xRemoved = xa.filter(n => !xb.includes(n));
const xAdded = xb.filter(n => !xa.includes(n));
check('xxhdpi split: 44 -> 48 images',
  xa.length === 44 && xb.length === 48, `${xa.length}/${xb.length}`);
check('xxhdpi removals all vendor holo selectors',
  xRemoved.length === 4 && xRemoved.every(n => n.includes('abc_list')));
check('xxhdpi adds planner onboarding webp (app asset)',
  xAdded.some(n => n.includes('academic_planner_onboarding')));

console.log(`\nassets-content-diff replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
