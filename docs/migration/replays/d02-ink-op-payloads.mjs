// Phase 870 — 墨迹 op payload 模式（类型 15–17）登记回归
// 证据：docs/migration/evidence/phase-870-ink-op-payloads.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- zq9 映射 ----
const zq9 = readFileSync(join(SRC, 'zq9.java'), 'utf8');
ok(zq9.includes('dm2.class), haa.CREATE_INK'), 'CREATE_INK -> dm2');
ok(zq9.includes('gd.class), haa.ADD_PATH_ELEMENTS'), 'ADD_PATH_ELEMENTS -> gd');
ok(zq9.includes('wd8.class), haa.MODIFY_INK'), 'MODIFY_INK -> wd8');

// ---- wd8：连续 19 字段 ----
const wd8 = readFileSync(join(SRC, 'wd8.java'), 'utf8');
const wd8Offsets = [...wd8.matchAll(/c\((\d+)\)/g)].map(m => +m[1]);
const wd8Fields = new Set(wd8Offsets.map(o => (o - 4) / 2));
ok(wd8Fields.size === 19 && wd8Fields.has(0) && wd8Fields.has(18),
  `wd8 has 19 contiguous fields f0-f18 (got ${wd8Fields.size})`);
ok(/cxc t\(\)[\s\S]{0,80}c\(6\)/.test(wd8), 'wd8 f1 = cxc position');
ok(/k2d u\(\)[\s\S]{0,80}c\(10\)/.test(wd8), 'wd8 f3 = k2d setter');
ok(/y2d v\(\)[\s\S]{0,80}c\(12\)/.test(wd8), 'wd8 f4 = y2d setter');
ok(/t16 w\(\)[\s\S]{0,80}c\(14\)/.test(wd8), 'wd8 f5 = t16 style update');
ok(/hu1 j\(\)[\s\S]{0,80}c\(16\)/.test(wd8), 'wd8 f6 = hu1 color');
ok(/Float z\(\)[\s\S]{0,80}c\(18\)/.test(wd8), 'wd8 f7 = Float width');
ok(/g2d n\(\)[\s\S]{0,80}c\(26\)/.test(wd8), 'wd8 f11 = g2d setter');
ok(wd8.includes('yyd C(yyd yydVar, int i)') && /c\(28\)/.test(wd8),
  'wd8 f12 = yyd vector (styleMap)');
ok(/tmf A\(\)[\s\S]{0,80}c\(30\)/.test(wd8), 'wd8 f13 = tmf timestamp');
ok(/ife y\(\)[\s\S]{0,80}c\(36\)/.test(wd8), 'wd8 f16 = ife');
ok(/Boolean p\(\)[\s\S]{0,80}c\(40\)/.test(wd8), 'wd8 f18 = Boolean');
ok(wd8.includes('void B(qo5 qo5Var, int i)') && /c\(4\)/.test(wd8),
  'wd8 f0 = qo5 vector (target ids)');

// ---- dm2：CREATE_INK ----
const dm2 = readFileSync(join(SRC, 'dm2.java'), 'utf8');
const dm2Fields = new Set([...dm2.matchAll(/c\((\d+)\)/g)].map(m => (+m[1] - 4) / 2));
ok(dm2Fields.size === 19, `dm2 has 19 vtable fields (got ${dm2Fields.size})`);
ok(/cxc t\(\)[\s\S]{0,80}c\(4\)/.test(dm2), 'dm2 f0 = cxc position');
ok(/hu1 k\(\)[\s\S]{0,80}c\(18\)/.test(dm2), 'dm2 f7 = hu1 color');
ok(/mmf j\(\)[\s\S]{0,80}c\(34\)/.test(dm2), 'dm2 f15 = mmf ink ordinal');
ok(/long o\(\)[\s\S]{0,80}c\(40\)/.test(dm2), 'dm2 f18 = long');

// ---- gd：ADD_PATH_ELEMENTS ----
const gd = readFileSync(join(SRC, 'gd.java'), 'utf8');
ok(/qo5 j\(\)/.test(gd), 'gd carries qo5 target ink id');

// ---- Harmony 等价 ----
const mie = readFileSync('note/src/main/ets/data/OriginalModifyInkPayloadEncoder.ets', 'utf8');
ok(mie.includes('new Array<number>(19)'), 'Harmony writes 19-field wd8 vtable');
ok(mie.includes('fields[5] = update.style === null ? 0 : 12'), 'fields[5]=style (t16/f5)');
ok(mie.includes('fields[6] = update.color === null ? 0 : 16'), 'fields[6]=color (hu1/f6)');
ok(mie.includes('fields[7] = update.width === null ? 0 : 20'), 'fields[7]=width (Float/f7)');
ok(mie.includes('fields[12] = styleMapVector === 0 ? 0 : 8'), 'fields[12]=styleMap (yyd vec)');
ok(mie.includes('wd8 has 19 fields'), 'encoder cites wd8 field count');
ok(mie.includes('u5j.q'), 'encoder cites u5j.q factory semantics');
const files = ['OriginalCreateInkPayloadEncoder.ets', 'OriginalAddPathElementsPayloadEncoder.ets',
               'OriginalModifyInkPayloadEncoder.ets', 'OriginalInkPathCodec.ets',
               'OriginalInkStyleMapCodec.ets'];
for (const f of files) {
  ok(readFileSync(`note/src/main/ets/data/${f}`, 'utf8').length > 500, `${f} exists`);
}

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
