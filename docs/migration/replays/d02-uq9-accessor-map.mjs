// Phase 905 — uq9 accessor→偏移全图回归
// 证据：docs/migration/evidence/phase-905-uq9-accessor-map.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const uq9 = rd('uq9.java');

// ---- accessor→c(N) 槽位 ----
ok(uq9.match(/tmf j\(\)[\s\S]{0,120}c\(10\)/), 'uq9.j() -> c(10) f3 audioTime');
ok(uq9.match(/long k\(\)[\s\S]{0,120}c\(6\)/), 'uq9.k() -> c(6) f1 clientTime');
ok(uq9.match(/qo5 l\(\)[\s\S]{0,120}p\(qo5Var\)/), 'uq9.l() -> p() id');
ok(uq9.match(/haa m\(\)[\s\S]{0,140}c\(12\)/), 'uq9.m() -> c(12) f4 payloadType');
ok(uq9.match(/tmf n\(\)[\s\S]{0,120}c\(8\)/), 'uq9.n() -> c(8) f2 serverTime');
ok(uq9.match(/qo5 p\(qo5[\s\S]{0,140}c\(4\)/), 'uq9.p() -> c(4) f0 id');
ok(uq9.match(/void q\(cee[\s\S]{0,140}c\(14\)/), 'uq9.q() -> c(14) f5 payload');
ok(uq9.match(/sdf r\(sdf[\s\S]{0,140}c\(16\)/), 'uq9.r() -> c(16) f6 transient');

// ---- 读法模式 ----
ok(uq9.includes('No value for (required) field id'), 'uq9 id required gate');
ok(uq9.includes('qo5Var.b(i, byteBuffer)'), 'uq9 id inline struct read');
ok(uq9.includes('byteBuffer.getInt(iC) + iC'), 'uq9 payload UOffsetT indirect');
ok(uq9.includes('iB = b(iC + this.I)'), 'uq9 sdf indirect via b()');

// ---- haa 前向兼容 ----
ok(uq9.includes('nz3Var.d()') && uq9.includes('nz3Var.get(0)'),
  'uq9 haa out-of-range -> entries[0] fallback');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
