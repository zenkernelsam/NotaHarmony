// Phase 875 — 子结构/值类/余枚举登记回归
// 证据：docs/migration/evidence/phase-875-substruct-valueclass-registry.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- ua0：64B SHA-512 资产哈希 ----
const ua0 = readFileSync(join(SRC, 'ua0.java'), 'utf8');
ok(ua0.includes('extends xwd'), 'ua0 = inline struct');
const ua0Longs = (ua0.match(/this\.J\.getLong\(this\.I(?: \+ \d+)?\)/g) || []).length;
ok(ua0Longs === 8, `ua0 = 8xLong 64B struct (SHA-512, got ${ua0Longs})`);

// ---- 内联结构布局 ----
ok(/getShort\(this\.I\)/.test(readFileSync(join(SRC, 'qo5.java'), 'utf8')), 'qo5 site short @+0');
ok(/getInt\(this\.I \+ 4\)/.test(readFileSync(join(SRC, 'qo5.java'), 'utf8')), 'qo5 ts int @+4');
const cxc = readFileSync(join(SRC, 'cxc.java'), 'utf8');
ok(cxc.includes('getInt(this.I + 8)') && cxc.includes('getShort(this.I)') &&
   cxc.includes('getInt(this.I + 4)'), 'cxc 12B {site,ts,index}');
const hu1 = readFileSync(join(SRC, 'hu1.java'), 'utf8');
ok((hu1.match(/this\.J\.get\(this\.I \+ [0-3]\)/g) || []).length === 4 ||
   hu1.includes('get(this.I + 3)'), 'hu1 = 4-byte RGBA');
const qed = readFileSync(join(SRC, 'qed.java'), 'utf8');
ok((qed.match(/getFloat\(this\.I(?: \+ \d+)?\)/g) || []).length === 2, 'qed = 2 floats');
const vy7 = readFileSync(join(SRC, 'vy7.java'), 'utf8');
ok((vy7.match(/getFloat\(this\.I(?: \+ \d+)?\)/g) || []).length === 4, 'vy7 = 4 floats');
const fqa = readFileSync(join(SRC, 'fqa.java'), 'utf8');
ok((fqa.match(/getFloat\(this\.I(?: \+ \d+)?\)/g) || []).length === 2, 'fqa = 2 floats');
const ukb = readFileSync(join(SRC, 'ukb.java'), 'utf8');
ok((ukb.match(/getLong\(this\.I(?: \+ \d+)?\)/g) || []).length === 2, 'ukb = 2 longs (segment)');
const utf = readFileSync(join(SRC, 'utf.java'), 'utf8');
ok((utf.match(/getLong\(this\.I(?: \+ \d+)?\)/g) || []).length === 2, 'utf = 2 longs (UUID)');

// ---- 值类 ----
for (const [cls, field] of [['tmf', 'long I'], ['xgb', 'long I'], ['mmf', 'int I'], ['cmf', 'byte I']]) {
  const body = readFileSync(join(SRC, `${cls}.java`), 'utf8');
  ok(body.includes(`public final ${field}`) && body.includes('implements Comparable'),
    `${cls} = Comparable value class {${field}}`);
}
ok(readFileSync(join(SRC, 'ymf.java'), 'utf8').includes('implements Comparable'),
  'ymf = Comparable value class');

// ---- 余枚举 ----
const ww9 = readFileSync(join(SRC, 'ww9.java'), 'utf8');
ok(ww9.includes('STRING((byte)') && ww9.includes('BOOLEAN((byte)'), 'ww9 = {STRING,BOOLEAN}');
const u76 = readFileSync(join(SRC, 'u76.java'), 'utf8');
ok(u76.includes('POINTER((byte)') && u76.includes('PEN((byte)') &&
   u76.includes('HIGHLIGHTER((byte)') && u76.includes('ERASER((byte)'), 'u76 = pointer types');

// ---- 小表 ----
for (const cls of ['z1d', 'lxc', 'm2d', 'akb']) {
  const body = readFileSync(join(SRC, `${cls}.java`), 'utf8');
  ok(body.includes('extends cee'), `${cls} = flatbuffer table`);
}

// ---- Harmony ua0 引用 ----
const ne = readFileSync('note/src/main/ets/data/NoteExporter.ets', 'utf8');
ok(ne.includes('assets/<sha512>') || ne.includes('ua0'), 'Harmony cites ua0/sha512 asset keys');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
