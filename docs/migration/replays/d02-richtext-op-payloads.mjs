// Phase 869 — 富文本 op payload 模式（类型 7–14）登记回归
// 证据：docs/migration/evidence/phase-869-richtext-op-payloads.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- zq9 映射 ----
const zq9 = readFileSync(join(SRC, 'zq9.java'), 'utf8');
const map = [['e46', 'INSERT_CHAR'], ['f46', 'INSERT_STRING'], ['pub', 'REMOVE_CHAR'],
             ['qub', 'REMOVE_CHARS'], ['f2c', 'REVIVE_CHARS'], ['me8', 'MODIFY_STYLE'],
             ['he8', 'MODIFY_PARAGRAPH_STYLE'], ['io1', 'CLEAR_STYLE']];
for (const [cls, name] of map) {
  ok(zq9.includes(`${cls}.class), haa.${name}`), `${name} -> ${cls}`);
}

// ---- 单位置 ops ----
const e46 = readFileSync(join(SRC, 'e46.java'), 'utf8');
ok(/cxc j\(\)[\s\S]{0,200}c\(4\)/.test(e46), 'e46 f0 = cxc position');
ok(/int l\(\)[\s\S]{0,200}c\(6\)/.test(e46), 'e46 f1 = int char');
ok(/qo5 k\(\)[\s\S]{0,200}c\(8\)/.test(e46), 'e46 f2 = qo5 target');
const f46 = readFileSync(join(SRC, 'f46.java'), 'utf8');
ok(/cxc j\(\)[\s\S]{0,200}c\(4\)/.test(f46), 'f46 f0 = cxc position');
ok(/String k\(\)[\s\S]{0,200}c\(6\)/.test(f46), 'f46 f1 = String text');
ok(/qo5 l\(\)[\s\S]{0,200}c\(8\)/.test(f46), 'f46 f2 = qo5 target');
const pub = readFileSync(join(SRC, 'pub.java'), 'utf8');
ok(/cxc j\(\)[\s\S]{0,200}c\(4\)/.test(pub), 'pub f0 = cxc position');
ok(/qo5 k\(\)[\s\S]{0,200}c\(6\)/.test(pub), 'pub f1 = qo5 target');

// ---- 向量 ops（qub/f2c：cxc vector + qo5） ----
for (const cls of ['qub', 'f2c']) {
  const body = readFileSync(join(SRC, `${cls}.java`), 'utf8');
  ok(body.includes(`void l(int i, cxc cxcVar)`) && body.includes('(i * 12)'),
    `${cls} f0 = cxc vector (12-byte stride)`);
  ok(/int j\(\)[\s\S]{0,120}i\(iC\)/.test(body), `${cls} j() = vector length`);
  ok(/qo5 k\(\)[\s\S]{0,200}c\(6\)/.test(body), `${cls} f1 = qo5 target`);
  ok(body.includes('Index out of range: '), `${cls} vector accessor fail-fast`);
}

// ---- io1 CLEAR_STYLE ----
const io1 = readFileSync(join(SRC, 'io1.java'), 'utf8');
ok(/v01 l\(\)[\s\S]{0,200}c\(4\)/.test(io1), 'io1 f0 = v01 range');
ok(/v01 j\(\)[\s\S]{0,200}c\(6\)/.test(io1), 'io1 f1 = v01 range');
ok(/boolean k\(\)[\s\S]{0,200}c\(8\)/.test(io1), 'io1 f2 = boolean');
ok(/qo5 m\(\)[\s\S]{0,200}c\(10\)/.test(io1), 'io1 f3 = qo5 target');

// ---- Harmony 等价 ----
const enc = readFileSync('note/src/main/ets/data/OriginalInsertTextPayloadEncoder.ets', 'utf8');
ok(enc.includes('ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE') &&
   enc.includes('ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE') &&
   enc.includes('ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE'), 'Harmony covers remove/revive types');
ok(enc.includes('visible ? ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE :\n    ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE') ||
   enc.includes('visible ? ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE'),
  'visible flag picks REVIVE vs REMOVE_CHARS');
const rts = readFileSync('note/src/main/ets/data/OriginalRichTextStyleOperation.ets', 'utf8');
ok(rts.includes('ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE: number = 12') &&
   rts.includes('ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE: number = 13') &&
   rts.includes('ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE: number = 14'), 'Harmony covers style types 12-14');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
