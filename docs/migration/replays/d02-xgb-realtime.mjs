// Phase 904 — xgb=Realtime 值类回归
// 证据：docs/migration/evidence/phase-904-xgb-realtime.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const xgb = rd('xgb.java');
const wq9 = rd('wq9.java');
const w0j = rd('w0j.java');
const uq9 = rd('uq9.java');

// ---- xgb = Realtime ----
ok(xgb.includes('public final class xgb implements Comparable'),
  'xgb Comparable value class');
ok(xgb.includes('public final long I'), 'xgb long field');
ok(xgb.includes('Realtime(value='), 'xgb toString = Realtime');
ok(xgb.includes('Long.compareUnsigned'), 'xgb unsigned long compare');
ok(xgb.includes('njj.j0(10, j)') || xgb.includes('njj.j0(10,'),
  'xgb unsigned radix-10 format');
ok(xgb.includes('public /* synthetic */ xgb(long j)'),
  'xgb inline-class constructor');

// ---- 使用点 ----
ok(wq9.includes('public final xgb d'), 'wq9.audioTime field = xgb');
ok(wq9.includes('(i & 16) != 0 ? null : xgbVar'), 'wq9 mask bit16 defaults xgb');
ok(w0j.includes('xgb xgbVar'), 'w0j.a xgb param');
ok(uq9.includes('public final tmf j()') && uq9.includes('public final long k()') &&
   uq9.includes('public final tmf n()'), 'uq9 time fields read as tmf/long (wire=ULong)');
ok(!uq9.includes('xgb'), 'uq9 wire side exposes tmf not xgb');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
