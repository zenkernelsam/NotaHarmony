// Phase 926 — yda=PeerInteraction + u76 枚举回归
// 证据：docs/migration/evidence/phase-926-peer-interaction-yda.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const yda = rd('yda.java');
const u76 = rd('u76.java');
const zq9 = rd('zq9.java');

ok(yda.includes('PeerInteraction(cursorPosition=') &&
   yda.includes('selectedEntities=') && yda.includes('textSelection=') &&
   yda.includes('recordingInProgress='), 'yda = PeerInteraction 5 fields');
ok(yda.match(/fqa j\(\)[\s\S]{0,140}c\(4\)/), 'cursorPosition fqa c(4)');
ok(yda.match(/qo5 o\(qo5 qo5Var, int i\)[\s\S]{0,160}c\(10\)/),
  'selectedEntities qo5[] c(10)');
ok(yda.match(/u76 n\(\)[\s\S]{0,140}c\(12\)/), 'tool u76 c(12)');
ok(yda.match(/qqe m\(\)[\s\S]{0,140}c\(14\)/), 'textSelection qqe c(14)');
ok(yda.match(/boolean k\(\)[\s\S]{0,120}c\(16\)/), 'recordingInProgress c(16)');
ok(yda.includes('lv2.d0(this)'), 'lv2.d0 selection materializer');

ok(u76.includes('POINTER((byte) 0)') && u76.includes('PEN((byte) 1)') &&
   u76.includes('HIGHLIGHTER((byte) 2)') && u76.includes('ERASER((byte) 3)'),
  'u76 = PeerTool POINTER/PEN/HIGHLIGHTER/ERASER');

ok(zq9.includes('yda.class') && zq9.includes('haa.PEER_INTERACTION'),
  'yda -> PEER_INTERACTION');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
