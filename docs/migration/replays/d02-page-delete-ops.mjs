// Phase 917 — ge8/s83/je8/tdf 读图回归
// 证据：docs/migration/evidence/phase-917-page-delete-ops.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const ge8 = rd('ge8.java');
const s83 = rd('s83.java');
const je8 = rd('je8.java');
const tdf = rd('tdf.java');
const zq9 = rd('zq9.java');

ok(ge8.includes('ModifyPage(pages=') && ge8.includes('moveTo=') &&
   ge8.includes('background=') && ge8.includes('bookmarked='),
  'ge8 = ModifyPage 4 fields');
ok(ge8.match(/lxc l\(\)[\s\S]{0,140}c\(6\)/), 'ge8 moveTo lxc c(6)');
ok(ge8.match(/m2d j\(\)[\s\S]{0,140}c\(8\)/), 'ge8 background m2d c(8)');
ok(ge8.match(/oz9 k\(\)[\s\S]{0,140}c\(10\)/), 'ge8 bookmarked oz9 c(10)');
ok(ge8.match(/void n\(int i, cxc cxcVar\)[\s\S]{0,160}c\(4\)/), 'ge8 pages cxc[] c(4)');

ok(s83.includes('DeleteEntities(entityDeletes=') &&
   s83.includes('entityUndeletes=') && s83.includes('pageDeletes=') &&
   s83.includes('pageUndeletes='), 's83 = DeleteEntities 4 tombstone vectors');
ok(s83.match(/qo5 j\(qo5 qo5Var, int i\)[\s\S]{0,140}c\(4\)/), 'entityDeletes c(4)');
ok(s83.match(/qo5 k\(qo5 qo5Var, int i\)[\s\S]{0,140}c\(6\)/), 'entityUndeletes c(6)');
ok(s83.match(/cxc p\(int i, cxc cxcVar\)[\s\S]{0,140}c\(8\)/), 'pageDeletes c(8)');
ok(s83.match(/cxc q\(int i, cxc cxcVar\)[\s\S]{0,140}c\(10\)/), 'pageUndeletes c(10)');

ok(je8.includes('ModifyPositions(modifications=') && je8.includes('lv2.S(this)'),
  'je8 = ModifyPositions ie8 vector');

ok(tdf.includes('TransientInteractionEnded(interactionId=') &&
   tdf.includes('replacedByOp='), 'tdf = TransientInteractionEnded');
ok(tdf.includes('No value for (required) field interactionId'),
  'tdf interactionId required');
ok(tdf.match(/qo5 k\(\)[\s\S]{0,140}c\(6\)/), 'tdf replacedByOp c(6)');

ok(zq9.includes('ge8.class') && zq9.includes('haa.MODIFY_PAGE'), 'ge8 -> MODIFY_PAGE');
ok(zq9.includes('s83.class') && zq9.includes('haa.DELETE_ENTITIES'), 's83 -> DELETE_ENTITIES');
ok(zq9.includes('je8.class') && zq9.includes('haa.MODIFY_POSITIONS'), 'je8 -> MODIFY_POSITIONS');
ok(zq9.includes('tdf.class') && zq9.includes('haa.TRANSIENT_INTERACTION_ENDED'),
  'tdf -> TRANSIENT_INTERACTION_ENDED');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
