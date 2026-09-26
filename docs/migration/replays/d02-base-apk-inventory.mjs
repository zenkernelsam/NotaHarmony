// Phase 815 replay: base-APK internal inventory closure.
// Pins dex 3->4, META-INF deltas (Metro DI, Singular bump,
// ink-storage, service-rename), and properties stability.
import fs from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability';
const APKS = {
  '1.0.1': `${ROOT}/Notability_1.0.1/com.gingerlabs.notability.apk`,
  '1.0.3': `${ROOT}/Notability_1.0.3/com.gingerlabs.notability.apk`,
  '1.4.2': `${ROOT}/Notability_1.4.2/com.gingerlabs.notability.apk`,
};

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok  ${name}`); }
  else { fail++; console.log(`FAIL  ${name} ${detail}`); }
}

// Minimal zip central-directory listing (names only).
function names(p) {
  const d = fs.readFileSync(p);
  const eocd = d.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  const count = d.readUInt16LE(eocd + 10);
  let off = d.readUInt32LE(eocd + 16);
  const out = [];
  for (let i = 0; i < count; i++) {
    const nlen = d.readUInt16LE(off + 28);
    const xlen = d.readUInt16LE(off + 30);
    const cmlen = d.readUInt16LE(off + 32);
    out.push(d.toString('utf8', off + 46, off + 46 + nlen));
    off += 46 + nlen + xlen + cmlen;
  }
  return out;
}

const N = Object.fromEntries(
  Object.entries(APKS).map(([v, p]) => [v, names(p)]));

for (const v of ['1.0.1', '1.0.3']) {
  check(`${v}: 3 dex`,
    N[v].filter(n => n.endsWith('.dex')).length === 3);
}
check('1.4.2: 4 dex (classes4.dex added)',
  N['1.4.2'].filter(n => n.endsWith('.dex')).length === 4 &&
  N['1.4.2'].includes('classes4.dex'));

const mi = v => new Set(N[v].filter(n => n.startsWith('META-INF/')));
const miA = mi('1.0.3'), miB = mi('1.4.2');
const miAdd = [...miB].filter(x => !miA.has(x));
const miRem = [...miA].filter(x => !miB.has(x));
check('META-INF delta +23/-15', miAdd.length === 23 && miRem.length === 15,
  `+${miAdd.length}/-${miRem.length}`);

check('Metro DI verification props added (7)',
  miAdd.filter(n => n.includes('zacsweers/metro')).length === 7);
check('ink-storage version file added (798 corroboration)',
  miAdd.includes('META-INF/androidx.ink_ink-storage.version'));
check('Singular bump 12.15 -> 12.16',
  miRem.some(n => n.includes('Singular-v12.15.0')) &&
  miAdd.some(n => n.includes('Singular-v12.16.0')));
check('jsoup license added (dead transitive dep)',
  miAdd.includes('META-INF/jsoup/LICENSE'));
check('okhttp native-image props removed',
  miRem.some(n => n.includes('native-image/okhttp')));
check('META-INF/services churn is pure rename (11->10)',
  miRem.filter(n => n.startsWith('META-INF/services/')).length === 11 &&
  miAdd.filter(n => n.startsWith('META-INF/services/')).length === 10);
check('13 non-service META-INF adds all registered',
  miAdd.filter(n => !n.startsWith('META-INF/services/')).length === 13);

// Top-level marker files stable.
for (const m of ['DebugProbesKt.bin', 'app-update.properties',
                 'billing.properties', 'asset-delivery.properties',
                 'common.properties']) {
  check(`${m} present in both versions`,
    N['1.0.3'].includes(m) && N['1.4.2'].includes(m));
}

// res member count shrinks (vendor pruning) while assets grow.
const res = v => N[v].filter(n => n.startsWith('res/')).length;
const assets = v => N[v].filter(n => n.startsWith('assets/')).length;
check('res members 665 -> 625 (vendor prune, matches 791/810)',
  res('1.0.3') === 665 && res('1.4.2') === 625);
check('assets members 115 -> 576 (matches 813)',
  assets('1.0.3') === 115 && assets('1.4.2') === 576);

console.log(`\nbase-apk-inventory replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
