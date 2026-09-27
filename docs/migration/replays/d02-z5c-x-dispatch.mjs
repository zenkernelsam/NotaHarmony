// Phase 932 — z5c.x 主载荷分发开关回归（31 序数权威交叉验证）
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const z5c = readFileSync(join(SRC, 'z5c.java'), 'utf8');

ok(z5c.includes('cee x(uq9 uq9Var)'), 'z5c.x = payload dispatcher');
ok(z5c.match(/case 0:[\s\S]{0,120}rgc\.b[\s\S]{0,60}throw null/), 'case 0 NONE hard-throws');

const ORDINAL_CLASSES = [
  [1, 'l2d', 'SetMetadata'], [2, 'ra0', 'AssetCloudPersisted'], [3, 'ln2', 'CreatePage'],
  [4, 'ge8', 'ModifyPage'], [5, 'yn2', 'CreateRecording'], [6, 'ke8', 'ModifyRecording'],
  [7, 'e46', 'InsertChar'], [8, 'f46', 'InsertString'], [9, 'pub', 'RemoveChar'],
  [10, 'qub', 'RemoveChars'], [11, 'f2c', 'ReviveChars'], [12, 'me8', 'ModifyStyle'],
  [13, 'he8', 'ModifyParagraphStyle'], [14, 'io1', 'ClearStyle'], [15, 'dm2', 'CreateInk'],
  [16, 'gd', 'AddPathElements'], [17, 'wd8', 'ModifyInk'], [18, 'ao2', 'CreateShape'],
  [19, 'le8', 'ModifyShape'], [20, 'cm2', 'CreateGroup'], [21, 'vd8', 'ModifyGroup'],
  [22, 'rl2', 'CreateBlock'], [23, 'td8', 'ModifyBlock'], [24, 'je8', 'ModifyPositions'],
  [25, 's83', 'DeleteEntities'], [26, 'tdf', 'TransientInteractionEnded'],
  [27, 'ee8', 'ModifyPDFField'], [28, 'mqf', 'UpdateCheckbox'], [29, 'yda', 'PeerInteraction'],
  [30, 'tl2', 'CreateComment'], [31, 'ud8', 'ModifyComment'],
];
for (const [n, cls, name] of ORDINAL_CLASSES) {
  ok(z5c.match(new RegExp('case (?:' + n + '|zn5\\.[A-Z_0-9]+ /\\* ' + n + ' \\*/):[\\s\\S]{0,80}new ' + cls + '\\(\\)')),
     `ordinal ${n} -> ${cls} (${name})`);
}
ok(z5c.includes('uq9Var.q('), 'dispatch ends with q() payload init');
ok(!z5c.match(/case \d+:[\s\S]{0,80}new zgb\(\)/), 'zgb not a payload type (envelope-level)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
