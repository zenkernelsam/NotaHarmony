// Phase 903 — f8d SharedNodeData + swc/qwc/rwc/hr5 回归
// 证据：docs/migration/evidence/phase-903-sharednode-crdt.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const f8d = rd('f8d.java');
const qwc = rd('qwc.java');
const rwc = rd('rwc.java');
const swc = rd('swc.java');

// ---- f8d SharedNodeData ----
ok(f8d.includes('SharedNodeData(rawSiteId='), 'f8d toString = SharedNodeData');
ok(f8d.includes('rawTimestamp=') && f8d.includes('rawAudioTime=') &&
   f8d.includes('parent=') && f8d.includes('values='),
  'f8d five named fields');
ok(f8d.includes('public final short a') && f8d.includes('public final int b') &&
   f8d.includes('public final long c') && f8d.includes('public final qwc d') &&
   f8d.includes('public final List e'), 'f8d field types');
ok(f8d.includes('hr5Var.J = this.a') && f8d.includes('hr5Var.K = this.b') &&
   f8d.includes('hr5Var.L = i'), 'f8d.a -> hr5 {site,ts,index} triple');

// ---- swc 接口 ----
ok(swc.includes('public interface swc'), 'swc interface');
ok(swc.includes('qwc a()') && swc.includes('long c()') &&
   swc.includes('hr5 d(hr5 hr5Var)') && swc.includes('rwc e(rwc rwcVar)') &&
   swc.includes('qwc getParent()'), 'swc five contract methods');

// ---- qwc 已解析引用 ----
ok(qwc.includes('public final class qwc implements swc'), 'qwc implements swc');
ok(qwc.includes('public final f8d a') && qwc.includes('public final int b'),
  'qwc {f8d,index}');
ok(qwc.includes('return this.a.c'), 'qwc.c() = rawAudioTime');
ok(qwc.includes('this.a.a(hr5Var, this.b)'), 'qwc.d exports via f8d.a');

// ---- rwc 惰性引用 ----
ok(rwc.includes('public final class rwc implements swc'), 'rwc implements swc');
ok(rwc.includes('public f8d a') && rwc.includes('int b = -1'),
  'rwc lazy {f8d=null,index=-1}');
ok(rwc.includes('new qwc(f8dVar, this.b)'), 'rwc.a() materializes qwc');
ok(rwc.includes('ba6.d0("sharedData")') || rwc.includes('d0("sharedData")'),
  'rwc unresolved sharedData gate');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
