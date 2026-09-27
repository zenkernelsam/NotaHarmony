// Phase 934 — t16/ty0/cz0 枚举 + dp5/akb 资产表回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const t16 = rd('t16.java');
ok(t16.includes('VARIABLE_WIDTH((byte) 0)') && t16.includes('FIXED_WIDTH((byte) 1)') &&
   t16.includes('DASH((byte) 2)') && t16.includes('DOTS((byte) 3)'), 't16 = StrokeStyle 4 values');
const ty0 = rd('ty0.java');
ok(ty0.includes('SQUARE((byte) 0)') && ty0.includes('ROUND((byte) 1)'), 'ty0 = CornerStyle');
const cz0 = rd('cz0.java');
ok(cz0.includes('TEXT((byte) 0)') && cz0.includes('IMAGE((byte) 1)') && cz0.includes('MATH((byte) 2)'),
  'cz0 = BlockType {TEXT,IMAGE,MATH}');

const dp5 = rd('dp5.java');
ok(dp5.match(/wa0 j\(\)[\s\S]{0,100}c\(4\)[\s\S]{0,80}required\) field metadata/), 'dp5 metadata wa0 required @c(4)');
ok(dp5.match(/qed k\(\)[\s\S]{0,100}c\(6\)[\s\S]{0,80}required\) field size/), 'dp5 size qed required @c(6)');
ok(dp5.includes('ImageAsset(metadata='), 'dp5 = ImageAsset');

const akb = rd('akb.java');
ok(akb.match(/wa0 j\(\)[\s\S]{0,100}c\(4\)[\s\S]{0,80}required\) field metadata/), 'akb metadata required @c(4)');
ok(akb.includes('RecordingAsset(metadata='), 'akb = RecordingAsset single-field');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
