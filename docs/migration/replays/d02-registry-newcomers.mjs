// Phase 950 — 注册表新五类型实名回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

ok(rd('p9.java').includes('AcknowledgeAppendedOpsEvent(acks='), 'p9 = AcknowledgeAppendedOpsEvent');
ok(rd('q89.java').includes('NoteMutationResponse(noteId=') && rd('q89.java').includes('acks='),
  'q89 = NoteMutationResponse{noteId,acks}');
ok(rd('q89.java').match(/utf l\(\)/), 'q89 noteId = utf');

const xq3 = rd('xq3.java');
ok(xq3.includes('extends xwd'), 'xq3 = inline struct');
ok(xq3.match(/qo5 d\(\)[\s\S]{0,60}this\.I\b/), 'DuplicateOp opId:qo5 @+0');
ok(xq3.match(/long e\(\)[\s\S]{0,60}this\.I \+ 8/), 'originalServerTime @+8');
ok(xq3.match(/long c\(\)[\s\S]{0,60}this\.I \+ 16/), 'duplicateServerTime @+16');
ok(xq3.includes('DuplicateOp(opId='), 'xq3 = DuplicateOp 24B');

ok(rd('r60.java').includes('abstract class r60 extends cee'), 'r60 = abstract cee base');
ok(rd('yq3.java').includes('abstract class yq3 extends cee'), 'yq3 = abstract cee base');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
