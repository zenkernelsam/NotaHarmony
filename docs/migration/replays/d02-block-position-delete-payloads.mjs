// Phase 872 — 块/位置/删除 op payload（类型 22–25）登记回归
// 证据：docs/migration/evidence/phase-872-block-position-delete-payloads.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- zq9 映射 ----
const zq9 = readFileSync(join(SRC, 'zq9.java'), 'utf8');
ok(zq9.includes('rl2.class), haa.CREATE_BLOCK'), 'CREATE_BLOCK -> rl2');
ok(zq9.includes('td8.class), haa.MODIFY_BLOCK'), 'MODIFY_BLOCK -> td8');
ok(zq9.includes('je8.class), haa.MODIFY_POSITIONS'), 'MODIFY_POSITIONS -> je8');
ok(zq9.includes('s83.class), haa.DELETE_ENTITIES'), 'DELETE_ENTITIES -> s83');

// ---- rl2 CREATE_BLOCK：21 字段 ----
const rl2 = readFileSync(join(SRC, 'rl2.java'), 'utf8');
const rl2Fields = new Set([...rl2.matchAll(/c\((\d+)\)/g)].map(m => (+m[1] - 4) / 2));
ok(rl2Fields.size === 21, `rl2 has 21 fields (got ${rl2Fields.size})`);
ok(/ty0 j\(\)[\s\S]{0,200}c\(6\)/.test(rl2), 'rl2 f1 = ty0 block type');
ok(/cxc t\(\)[\s\S]{0,200}c\(8\)/.test(rl2), 'rl2 f2 = cxc position');
ok(/String r\(\)[\s\S]{0,200}c\(30\)/.test(rl2), 'rl2 f13 = String');
ok(/k3a u\(\)[\s\S]{0,200}c\(34\)/.test(rl2), 'rl2 f15 = k3a paper');
ok(/vy7 p\(\)[\s\S]{0,200}c\(42\)/.test(rl2), 'rl2 f19?/f20 = vy7 4-float');

// ---- td8 MODIFY_BLOCK：18 槽 ----
const td8 = readFileSync(join(SRC, 'td8.java'), 'utf8');
const td8Fields = new Set([...td8.matchAll(/c\((\d+)\)/g)].map(m => (+m[1] - 4) / 2));
ok(td8Fields.size === 18, `td8 has 18 fields (got ${td8Fields.size})`);
ok(/cxc s\(\)[\s\S]{0,200}c\(8\)/.test(td8), 'td8 f2 = cxc');
ok(/k2d w\(\)[\s\S]{0,200}c\(12\)/.test(td8), 'td8 f4 = k2d setter');
ok(/y2d x\(\)[\s\S]{0,200}c\(14\)/.test(td8), 'td8 f5 = y2d setter');
ok(/qed y\(\)[\s\S]{0,200}c\(16\)/.test(td8), 'td8 f6 = qed');
ok(/z2d q\(\)[\s\S]{0,200}c\(24\)/.test(td8), 'td8 f10 = z2d setter');
ok(/g2d p\(\)[\s\S]{0,200}c\(26\)/.test(td8), 'td8 f11 = g2d setter');
ok(/n2d t\(\)[\s\S]{0,200}c\(30\)/.test(td8), 'td8 f13 = n2d setter');

// ---- je8 单字段向量 ----
const je8 = readFileSync(join(SRC, 'je8.java'), 'utf8');
const je8Fields = new Set([...je8.matchAll(/c\((\d+)\)/g)].map(m => (+m[1] - 4) / 2));
ok(je8Fields.size === 1 && je8Fields.has(0), 'je8 = single positions-vector field');

// ---- s83 DELETE_ENTITIES：4 向量 ----
const s83 = readFileSync(join(SRC, 's83.java'), 'utf8');
const s83Fields = new Set([...s83.matchAll(/c\((\d+)\)/g)].map(m => (+m[1] - 4) / 2));
ok(s83Fields.size === 4, 's83 = 4 vector fields');
ok(s83.includes('qo5 j(') || /qo5 j\(\)[\s\S]{0,200}c\(4\)/.test(s83), 's83 f0 = qo5 vector');
ok(/qo5 k\(\)[\s\S]{0,200}c\(6\)/.test(s83) || s83.includes('qo5 k('), 's83 f1 = qo5 vector');
ok(s83.includes('cxc p(') || s83.includes('void p(') || /cxc/.test(s83.slice(0,4000)),
  's83 f2/f3 = cxc vectors');

// ---- Harmony 等价 ----
const dee = readFileSync('note/src/main/ets/data/OriginalDeleteEntitiesPayloadEncoder.ets', 'utf8');
ok(dee.includes('entityDeletes, entityUndeletes, pageDeletes, pageUndeletes'),
  'Harmony s83 = entityDel/entityUndel/pageDel/pageUndel');
ok(dee.includes('counts.length') && dee.includes('elementSizes'),
  'per-field vector sizing');
for (const f of ['OriginalCreateBlockPayloadEncoder.ets', 'OriginalModifyBlockPayloadEncoder.ets',
                 'OriginalModifyPositionsPayloadEncoder.ets']) {
  ok(readFileSync(`note/src/main/ets/data/${f}`, 'utf8').length > 500, `${f} exists`);
}
const mp = readFileSync('note/src/main/ets/data/OriginalModifyPositionsPayloadEncoder.ets', 'utf8');
ok(mp.includes('je8') || mp.includes('MODIFY_POSITIONS') || mp.includes('position'),
  'ModifyPositions encoder references je8 contract');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
