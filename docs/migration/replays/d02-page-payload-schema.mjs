// Phase 867 — 页面 payload 模式（ln2/nz9/sw9/子结构）登记回归
// 证据：docs/migration/evidence/phase-867-page-payload-schema.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- ln2 = CreatePage payload ----
const ln2 = readFileSync(join(SRC, 'ln2.java'), 'utf8');
ok(ln2.includes('extends cee implements ka4'), 'ln2 = flatbuffer table');
ok(/nz9 j\(\)[\s\S]{0,300}c\(6\)/.test(ln2), 'ln2 f1 (c(6)) = nz9 background');
ok(/cxc l\(\)[\s\S]{0,300}c\(4\)/.test(ln2), 'ln2 f0 (c(4)) = cxc position');
ok(/int m\(\)[\s\S]{0,200}c\(8\)[\s\S]{0,200}return 1/.test(ln2) ||
   ln2.includes('return 1;'), 'ln2 f2 (c(8)) pageInAsset int default 1');
ok(/oz9 k\(\)[\s\S]{0,400}c\(10\)/.test(ln2), 'ln2 f3 (c(10)) = oz9 bookmark byte');

// ---- nz9 = 页面外观表 ----
const nz9 = readFileSync(join(SRC, 'nz9.java'), 'utf8');
ok(nz9.includes('extends cee implements ka4'), 'nz9 = flatbuffer table');
ok(/sw9 l\(\)[\s\S]{0,200}c\(6\)/.test(nz9), 'nz9 f1 (c(6)) = sw9 pdf-in-asset');
ok(/k3a k\(\)[\s\S]{0,200}c\(4\)/.test(nz9), 'nz9 f0 (c(4)) = k3a background sub-table');
ok(/float m\(\)[\s\S]{0,200}c\(8\)[\s\S]{0,150}0\.0f/.test(nz9), 'nz9 f2 (c(8)) float default 0.0');
ok(/qed n\(\)[\s\S]{0,200}c\(10\)/.test(nz9), 'nz9 f3 (c(10)) = qed 2-float struct');
ok(/vy7 j\(\)[\s\S]{0,200}c\(12\)/.test(nz9), 'nz9 f4 (c(12)) = vy7 4-float struct');

// ---- sw9 = PDF-in-asset ----
const sw9 = readFileSync(join(SRC, 'sw9.java'), 'utf8');
ok(/wa0 m\(\)[\s\S]{0,200}c\(4\)/.test(sw9), 'sw9 f0 (c(4)) = wa0 pdf asset ref');
ok(/xw9 l\(\)[\s\S]{0,200}c\(6\)/.test(sw9), 'sw9 f1 (c(6)) = xw9 range/info');
ok(sw9.includes('void j(int i, qed qedVar)'), 'sw9 has qed element writer (page-size vector)');
ok(/int n\(\)/.test(sw9), 'sw9.n() = pdf page count (wz9.m offset basis)');

// ---- 内联结构/值类 ----
const vy7 = readFileSync(join(SRC, 'vy7.java'), 'utf8');
ok(vy7.includes('extends xwd implements ka4'), 'vy7 = inline struct');
ok((vy7.match(/public final float [a-z]\(\)/g) || []).length >= 4, 'vy7 = 4 floats (c/d/e/f)');
const qed = readFileSync(join(SRC, 'qed.java'), 'utf8');
ok(qed.includes('extends xwd implements ka4') &&
   (qed.match(/public final float [a-z]\(\)/g) || []).length >= 2, 'qed = 2 floats (c/d)');
const mmf = readFileSync(join(SRC, 'mmf.java'), 'utf8');
ok(mmf.includes('implements Comparable') && mmf.includes('public final int I'),
  'mmf = inline int value class (pageInAsset ordinal)');

// ---- oz9 枚举安全解码（ln2.k） ----
ok(ln2.includes('nz3Var.get(0)'), 'ln2.k() falls back to oz9[0]=UNBOOKMARKED on bad byte');

// ---- Harmony 等价 ----
const enc = readFileSync('note/src/main/ets/data/OriginalCreatePagePayloadEncoder.ets', 'utf8');
ok(enc.includes('writeSequence'), 'Harmony writes cxc sequence struct');
ok(enc.includes('writeU16(bytes, offset, value.siteId)') &&
   enc.includes('writeU32(bytes, offset + 4, value.timestamp)') &&
   enc.includes('writeU32(bytes, offset + 8, value.index)'),
  'cxc layout: site@0 ts@4 index@8 (matches ln2 f0)');
ok(enc.includes('ln2') && enc.includes('nz9'), 'encoder cites original table names');
ok(enc.includes('bookmark'), 'encoder carries bookmark field (ln2 f3)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
