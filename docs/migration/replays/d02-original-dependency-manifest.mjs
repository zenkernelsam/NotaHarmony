// D02 原版 1.4.2 依赖清单差 + multidex — Phase 798
import assert from 'node:assert/strict';
import fs from 'node:fs';
import zlib from 'node:zlib';

const X103 = 'C:/Users/Cisco He/Desktop/Notability/Notability_1.0.3/Notability_+AI+Note+Workspace_1.0.3_APKPure.xapk';
const X142 = 'C:/Users/Cisco He/Desktop/Notability/Notability_1.4.2/Notability%3A+AI+Note+Workspace_1.4.2_apkcombo.com.xapk';

const apkEntries = (buf) => {
  const e = buf.lastIndexOf(Buffer.from('PK\x05\x06'));
  const n = buf.readUInt16LE(e + 10);
  let o = buf.readUInt32LE(e + 16);
  const m = new Map();
  for (let i = 0; i < n; i++) {
    const nl = buf.readUInt16LE(o + 28);
    m.set(buf.slice(o + 46, o + 46 + nl).toString(), {
      csz: buf.readUInt32LE(o + 20), cm: buf.readUInt16LE(o + 10),
      lh: buf.readUInt32LE(o + 42),
    });
    o += 46 + nl + buf.readUInt16LE(o + 30) + buf.readUInt16LE(o + 32);
  }
  return m;
};
const readEntry = (b, e) => {
  const ln = b.readUInt16LE(e.lh + 26), le = b.readUInt16LE(e.lh + 28);
  const d = b.slice(e.lh + 30 + ln + le, e.lh + 30 + ln + le + e.csz);
  return e.cm === 8 ? zlib.inflateRawSync(d) : d;
};
const baseEntries = (xapkPath) => {
  const x = apkEntries(fs.readFileSync(xapkPath));
  return apkEntries(readEntry(fs.readFileSync(xapkPath), x.get('com.gingerlabs.notability.apk')));
};

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const e103 = baseEntries(X103), e142 = baseEntries(X142);
const v103 = [...e103.keys()].filter((k) => /^META-INF\/.*\.version$/.test(k));
const v142 = [...e142.keys()].filter((k) => /^META-INF\/.*\.version$/.test(k));

check('META-INF .version inventory: 129 -> 130',
  v103.length === 129 && v142.length === 130);
check('sole .version addition is androidx.ink_ink-storage',
  v142.filter((k) => !new Set(v103).has(k)).join(',')
    === 'META-INF/androidx.ink_ink-storage.version'
  && v103.every((k) => v142.includes(k)));
check('AndroidX Ink engine pre-existed in 1.0.3 (six libs)',
  ['ink-authoring', 'ink-brush', 'ink-geometry', 'ink-nativeloader',
    'ink-rendering', 'ink-strokes']
    .every((l) => v103.includes(`META-INF/androidx.ink_${l}.version`)));
check('multidex grew 3 -> 4',
  [...e103.keys()].filter((k) => /^classes\d*\.dex$/.test(k)).length === 3
  && [...e142.keys()].filter((k) => /^classes\d*\.dex$/.test(k)).length === 4);

console.log(`dependency-manifest replay: ${checks.length}/${checks.length} checks green`);
