// Phase 939 — s83/tdf/je8/ge8/tl2/ud8 偏移回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const s83 = rd('s83.java');
ok(s83.includes('DeleteEntities(entityDeletes='), 's83 = DeleteEntities');
for (const [m, off] of [['l', 4], ['m', 6], ['n', 8], ['o', 10]]) {
  ok(s83.match(new RegExp('Integer ' + m + '\\(\\)[\\s\\S]{0,60}c\\(' + off + '\\)')),
     `s83 vector @c(${off})`);
}

const tdf = rd('tdf.java');
ok(tdf.includes('TransientInteractionEnded(interactionId=') && tdf.includes('replacedByOp='),
  'tdf = {interactionId,replacedByOp}');

ok(rd('je8.java').includes('ModifyPositions(modifications='), 'je8 = ModifyPositions');

const ge8 = rd('ge8.java');
ok(ge8.includes('ModifyPage(pages=') && ge8.includes('moveTo=') && ge8.includes('background=') &&
   ge8.includes('bookmarked='), 'ge8 = ModifyPage 4 fields');
ok(ge8.match(/lxc l\(\)[\s\S]{0,80}c\(6\)/), 'ge8 moveTo lxc @c(6)');
ok(ge8.match(/m2d j\(\)[\s\S]{0,80}c\(8\)/), 'ge8 background m2d @c(8)');
ok(ge8.match(/oz9 k\(\)[\s\S]{0,80}c\(10\)/), 'ge8 bookmarked oz9 @c(10)');

const tl2 = rd('tl2.java');
ok(tl2.match(/im j\(\)[\s\S]{0,60}c\(4\)/), 'tl2 anchorKind @c(4)');
ok(tl2.match(/String k\(\)[\s\S]{0,60}c\(8\)/), 'tl2 text @c(8)');

const ud8 = rd('ud8.java');
ok(ud8.match(/qo5 k\(\)[\s\S]{0,80}c\(4\)/), 'ud8 comment @c(4)');
ok(ud8.match(/hd1 j\(\)[\s\S]{0,80}c\(6\)/), 'ud8 anchor = hd1 only (non-polymorphic!) @c(6)');
ok(ud8.match(/z2d m\(\)[\s\S]{0,80}c\(8\)/), 'ud8 text z2d @c(8)');
ok(ud8.match(/z1d l\(\)[\s\S]{0,80}c\(10\)/), 'ud8 resolved z1d @c(10)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
