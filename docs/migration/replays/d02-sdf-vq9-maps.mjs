// Phase 907 — sdf/vq9 accessor 偏移图回归
// 证据：docs/migration/evidence/phase-907-sdf-vq9-maps.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const sdf = rd('sdf.java');
const vq9 = rd('vq9.java');

// ---- sdf = TransientInteraction ----
ok(sdf.includes('TransientInteraction(interactionId='), 'sdf toString');
ok(sdf.includes('timeout='), 'sdf timeout field');
ok(sdf.match(/qo5 l\(qo5[\s\S]{0,120}c\(4\)/), 'sdf.l -> c(4) interactionId');
ok(sdf.match(/mmf k\(\)[\s\S]{0,120}c\(6\)/), 'sdf.k -> c(6) timeout UInt');
ok(sdf.includes('extends cee implements ka4'), 'sdf cee+ka4');

// ---- vq9 = OpAck ----
ok(vq9.includes('OpAck(id='), 'vq9 toString = OpAck');
ok(vq9.includes('timestampedOp=') && vq9.includes('nakError=') &&
   vq9.includes('duplicate='), 'vq9 four named fields');
ok(vq9.match(/qo5 k\(\)[\s\S]{0,120}c\(4\)/), 'vq9.k -> c(4) id');
ok(vq9.match(/uq9 n\(uq9[\s\S]{0,140}c\(6\)/), 'vq9.n -> c(6) timestampedOp');
ok(vq9.match(/String l\(\)[\s\S]{0,120}c\(8\)/), 'vq9.l -> c(8) nakError');
ok(vq9.match(/Boolean j\(\)[\s\S]{0,120}c\(10\)/), 'vq9.j -> c(10) duplicate');
ok(vq9.includes('extends cee implements ka4'), 'vq9 cee+ka4');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
