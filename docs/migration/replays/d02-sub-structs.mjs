// Phase 923 — ukb/bmb/qqe/yyd 子结构回归
// 证据：docs/migration/evidence/phase-923-sub-structs.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const ukb = rd('ukb.java');
ok(ukb.includes('RecordingSegment(startTime=') && ukb.includes('endTime='),
  'ukb = RecordingSegment');
ok(ukb.includes('getLong(this.I)') && ukb.includes('getLong(this.I + 8)'),
  'ukb 16B {start@0,end@8}');
ok(ukb.includes('extends xwd'), 'ukb inline struct');

const bmb = rd('bmb.java');
ok(bmb.includes('Rect(origin=') && bmb.includes('size='), 'bmb = Rect');
ok(bmb.match(/fqa c\(\)/) && bmb.match(/qed d\(\)/), 'bmb = {fqa origin, qed size}');
ok(bmb.includes('extends xwd'), 'bmb inline struct');

const qqe = rd('qqe.java');
ok(qqe.includes('TextSelection(anchor=') && qqe.includes('focus='),
  'qqe = TextSelection');
ok(qqe.match(/c\(4\)/) && qqe.match(/c\(6\)/), 'qqe 2-slot v01 boundaries');
ok(qqe.includes('extends cee'), 'qqe is table');

const yyd = rd('yyd.java');
ok(yyd.includes('StyleMap(backingPencilSeed=') &&
   yyd.includes('backingPencilReferencePoint=') &&
   yyd.includes('backingDashPhase=') && yyd.includes('backingDashPeriod='),
  'yyd = StyleMap dash-render params');
ok(yyd.includes('getInt(this.I)') && yyd.includes('getFloat(this.I + 12)') &&
   yyd.includes('getFloat(this.I + 16)'), 'yyd layout int@0/float@12/@16');
ok(yyd.includes('extends xwd'), 'yyd inline struct');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
