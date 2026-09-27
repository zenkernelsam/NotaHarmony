// Phase 922 — yn2/ke8 录音 op 读图回归
// 证据：docs/migration/evidence/phase-922-recording-ops.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const yn2 = rd('yn2.java');
const ke8 = rd('ke8.java');
const zq9 = rd('zq9.java');

ok(yn2.includes('CreateRecording(recording=') && yn2.includes('startTime=') &&
   yn2.includes('endTime=') && yn2.includes('segmentation=') &&
   yn2.includes('zIndex='), 'yn2 = CreateRecording 6 fields');
ok(yn2.match(/akb l\(\)[\s\S]{0,140}c\(4\)/), 'recording akb c(4)');
ok(yn2.match(/long m\(\)[\s\S]{0,120}c\(6\)/), 'startTime long c(6)');
ok(yn2.match(/long j\(\)[\s\S]{0,120}c\(8\)/), 'endTime long c(8)');
ok(yn2.match(/String k\(\)[\s\S]{0,120}c\(10\)/), 'name c(10)');
ok(yn2.match(/ukb o\(ukb ukbVar, int i\)[\s\S]{0,200}c\(12\)/), 'segmentation ukb[] c(12)');
ok(yn2.includes('(i * 16) + f(iC)'), 'ukb 16B inline-struct vector');
ok(yn2.match(/tmf n\(\)[\s\S]{0,120}c\(14\)/), 'zIndex tmf c(14)');
ok(yn2.includes('lv2.b0(this)'), 'lv2.b0 segmentation materializer');

ok(ke8.includes('ModifyRecording(recording=') && ke8.includes('segmentation=') &&
   ke8.includes('lv2.c0(this)'), 'ke8 = ModifyRecording 4 fields');
ok(ke8.match(/qo5 k\(\)|k\(\)[\s\S]{0,140}c\(4\)/), 'recording qo5 c(4)');
ok(ke8.match(/c\(6\)/) && ke8.match(/c\(10\)/), 'name/zIndex slots');

ok(zq9.includes('yn2.class') && zq9.includes('haa.CREATE_RECORDING'),
  'yn2 -> CREATE_RECORDING');
ok(zq9.includes('ke8.class') && zq9.includes('haa.MODIFY_RECORDING'),
  'ke8 -> MODIFY_RECORDING');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
