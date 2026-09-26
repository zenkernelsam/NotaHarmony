// Phase 860 — zq9 表↔类型注册表 + Op 写入器登记回归
// 证据：docs/migration/evidence/phase-860-payload-type-registry.md
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'note/src/main/ets/data';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- zq9 权威映射：31 条 表↔类型 ----
const zq9 = readFileSync(join(SRC, 'zq9.java'), 'utf8');
const pairs = [...zq9.matchAll(/npbVar\.b\(([a-z0-9]+)\.class\), haa\.([A-Z_]+)/g)]
  .map(m => [m[1], m[2]]);
ok(pairs.length === 31, `zq9 maps 31 table classes to haa types (got ${pairs.length})`);
const expect = {
  l2d: 'SET_METADATA', ra0: 'ASSET_CLOUD_PERSISTED', ln2: 'CREATE_PAGE',
  ge8: 'MODIFY_PAGE', yn2: 'CREATE_RECORDING', ke8: 'MODIFY_RECORDING',
  e46: 'INSERT_CHAR', f46: 'INSERT_STRING', pub: 'REMOVE_CHAR',
  qub: 'REMOVE_CHARS', f2c: 'REVIVE_CHARS', me8: 'MODIFY_STYLE',
  he8: 'MODIFY_PARAGRAPH_STYLE', io1: 'CLEAR_STYLE', dm2: 'CREATE_INK',
  gd: 'ADD_PATH_ELEMENTS', wd8: 'MODIFY_INK', ao2: 'CREATE_SHAPE',
  le8: 'MODIFY_SHAPE', cm2: 'CREATE_GROUP', vd8: 'MODIFY_GROUP',
  rl2: 'CREATE_BLOCK', td8: 'MODIFY_BLOCK', je8: 'MODIFY_POSITIONS',
  s83: 'DELETE_ENTITIES', tdf: 'TRANSIENT_INTERACTION_ENDED',
  ee8: 'MODIFY_PDF_FIELD', mqf: 'UPDATE_CHECKBOX', yda: 'PEER_INTERACTION',
  tl2: 'CREATE_COMMENT', ud8: 'MODIFY_COMMENT',
};
for (const [cls, type] of pairs) {
  ok(expect[cls] === type, `zq9 ${cls} -> ${type} (expected ${expect[cls]})`);
}
ok(zq9.includes('rgc.b'), 'unmapped class fails closed via rgc.b throw');
ok(zq9.includes('aVar.C(7)'), 'Op writer startTable(7)');
ok(zq9.includes('aVar.z(iN, 4)') && zq9.includes('aVar.z(iN, 14)'),
  'Op writer marks id(0) and payload(5) required');
ok(zq9.includes('aVar.c(4, b(ceeVar).I, 0)'), 'payloadType@4 written as byte, default NONE');

// ---- sdf transient-interaction 副信道表 ----
const sdf = readFileSync(join(SRC, 'sdf.java'), 'utf8');
ok(sdf.includes('TransientInteraction(interactionId='), 'sdf = TransientInteraction');
ok(sdf.includes('timeout='), 'sdf carries timeout field');
ok(sdf.includes('c(4)') && sdf.includes('c(6)'), 'sdf two fields: interactionId@0 timeout@1');

// ---- Harmony：31 常量逐值一致（zq9 视角复核）----
const haa = Object.fromEntries([...readFileSync(join(SRC, 'haa.java'), 'utf8')
  .matchAll(/([A-Z_]+)\(\(byte\) (\d+)\)/g)].map(m => [m[1], +m[2]]));
let bad = 0;
for (const [type, v] of Object.entries(haa)) {
  if (v === 0) continue;
  const cname = `ORIGINAL_${type}_PAYLOAD_TYPE: number = ${v}`;
  const found = readdirSync(HARM).filter(f => f.endsWith('.ets'))
    .some(f => readFileSync(join(HARM, f), 'utf8').includes(cname));
  if (!found) { bad++; console.log('  missing/mismatched:', cname); }
}
ok(bad === 0, `all zq9 payload types match Harmony constants (${bad} bad)`);

// ---- Harmony transient-encoder 编码 type-26 双恒等槽 ----
const ti = readFileSync(join(HARM, 'OriginalTransientInteractionPayloadEncoder.ets'), 'utf8');
ok(ti.includes('replacedByOp'), 'transient-ended encoder carries replacedByOp');
ok(ti.includes('writeIdentity'), 'transient-ended encoder writes qo5 identities');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
