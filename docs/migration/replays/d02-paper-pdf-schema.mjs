// Phase 868 — 纸张/PDF 子模式（k3a/n3a/hu1/wa0/xw9/ge8）登记回归
// 证据：docs/migration/evidence/phase-868-paper-pdf-schema.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- ge8 = MODIFY_PAGE payload ----
const ge8 = readFileSync(join(SRC, 'ge8.java'), 'utf8');
ok(ge8.includes('extends cee implements ka4'), 'ge8 = flatbuffer table with ka4');
ok(/lxc l\(\)[\s\S]{0,200}c\(6\)/.test(ge8), 'ge8 f1 (c(6)) = lxc moveTo');
ok(/m2d j\(\)[\s\S]{0,200}c\(8\)/.test(ge8), 'ge8 f2 (c(8)) = m2d background');
ok(/oz9 k\(\)[\s\S]{0,300}c\(10\)/.test(ge8), 'ge8 f3 (c(10)) = oz9 bookmark');

// ---- k3a = 纸张背景表 ----
const k3a = readFileSync(join(SRC, 'k3a.java'), 'utf8');
ok(/n3a k\(\)[\s\S]{0,200}c\(4\)/.test(k3a), 'k3a f0 (c(4)) = n3a paper pattern');
ok(/Float n\(\)[\s\S]{0,200}c\(6\)/.test(k3a), 'k3a f1 (c(6)) = Float spacing');
ok(/Boolean l\(\)[\s\S]{0,200}c\(8\)/.test(k3a), 'k3a f2 (c(8)) = Boolean');
ok(/Boolean m\(\)[\s\S]{0,200}c\(10\)/.test(k3a), 'k3a f3 (c(10)) = Boolean');
ok(/hu1 j\(\)[\s\S]{0,200}c\(12\)/.test(k3a), 'k3a f4 (c(12)) = hu1 color');
ok(/cmf o\(\)[\s\S]{0,200}c\(14\)/.test(k3a), 'k3a f5 (c(14)) = cmf');

// ---- n3a / xw9 枚举 ----
const n3a = readFileSync(join(SRC, 'n3a.java'), 'utf8');
ok(n3a.includes('LINES((byte) 0)') && n3a.includes('DOTS((byte) 1)') &&
   n3a.includes('GRID((byte) 2)'), 'n3a = {LINES,DOTS,GRID}');
const xw9 = readFileSync(join(SRC, 'xw9.java'), 'utf8');
ok(xw9.includes('DOWNSCALING_AND_MAX_BOX((byte) 0)') &&
   xw9.includes('DOWNSCALING_AND_CROP_BOX((byte) 1)') &&
   xw9.includes('FIT_AND_CROP_BOX((byte) 2)'), 'xw9 = pdf-fit enum x3');

// ---- hu1 = RGBA 4B struct ----
const hu1 = readFileSync(join(SRC, 'hu1.java'), 'utf8');
ok(hu1.includes('extends xwd implements ka4'), 'hu1 = inline struct');
ok((hu1.match(/public final byte [a-z]\(\)/g) || []).length >= 4, 'hu1 = 4 bytes (RGBA)');

// ---- wa0 = pdf 资产表 ----
const wa0 = readFileSync(join(SRC, 'wa0.java'), 'utf8');
ok(/ua0 j\(\)[\s\S]{0,200}c\(4\)/.test(wa0), 'wa0 f0 (c(4)) = ua0 sub-table');
ok(/String k\(\)[\s\S]{0,200}c\(6\)/.test(wa0), 'wa0 f1 (c(6)) = String');
ok(/String m\(\)[\s\S]{0,200}c\(8\)/.test(wa0), 'wa0 f2 (c(8)) = String');
ok(/int l\(\)[\s\S]{0,200}c\(10\)[\s\S]{0,120}return 0/.test(wa0), 'wa0 f3 (c(10)) int default 0');

// ---- zq9 登记 ----
const zq9 = readFileSync(join(SRC, 'zq9.java'), 'utf8');
ok(zq9.includes('ln2.class), haa.CREATE_PAGE'), 'CREATE_PAGE -> ln2');
ok(zq9.includes('ge8.class), haa.MODIFY_PAGE'), 'MODIFY_PAGE -> ge8');

// ---- Harmony 等价 ----
const pbm = readFileSync('note/src/main/ets/core/model/PageBackgroundModel.ets', 'utf8');
ok(pbm.includes('OriginalPaperFlair.LINES') && pbm.includes('OriginalPaperFlair.DOTS') &&
   pbm.includes('OriginalPaperFlair.GRID'), 'Harmony PaperFlair = n3a enum');
ok(pbm.includes('flairBleeds: template !== PaperTemplate.LINES'),
  'LINES non-bleeding vs DOTS/GRID bleed semantics');
const mpe = readFileSync('note/src/main/ets/data/OriginalModifyPagePayloadEncoder.ets', 'utf8');
ok(mpe.includes('ge8') && mpe.includes('moveTo') && mpe.includes('m2d'),
  'ModifyPage encoder cites ge8/lxc/m2d fields');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
