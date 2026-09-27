// Phase 881 — wq9/xq9 op 实例化层回归
// 证据：docs/migration/evidence/phase-881-op-instantiation.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const wq9 = rd('wq9.java');
const xq9 = rd('xq9.java');

// ---- wq9 = OpCreationMetadata ----
ok(wq9.includes('OpCreationMetadata(payload='), 'wq9 toString = OpCreationMetadata');
ok(wq9.includes('public wq9(cee ceeVar, qo5 qo5Var, boolean z, xgb xgbVar, int i)'),
  'wq9 ctor signature');
ok(wq9.includes('(i & 2) != 0 ? null : qo5Var'), 'wq9 mask bit1 -> transientId null');
ok(wq9.includes('(i & 4) != 0 ? false : z'), 'wq9 mask bit2 -> transient false');
ok(wq9.includes('(i & 16) != 0 ? null : xgbVar'), 'wq9 mask bit4 -> audioTime null');
ok(wq9.includes('transientTimeout=null'), 'wq9 elided param3 = transientTimeout');
ok(wq9.includes('zq9.b(ceeVar).ordinal()'), 'wq9 auto-transient via payload type');
ok(wq9.includes('case 26:') && wq9.includes('29'), 'wq9 types 26/29 auto-transient');

// ---- wq9 字段 ----
ok(wq9.includes('public final cee a') && wq9.includes('public final boolean b') &&
   wq9.includes('public final qo5 c') && wq9.includes('public final xgb d') &&
   wq9.includes('public final boolean e') && wq9.includes('public final qo5 f'),
  'wq9 fields payload/transient/inProgressId/audioTime');

// ---- xq9 实例化 ----
ok(xq9.includes('public final qo5 a(wq9 wq9Var)'), 'xq9.a apply lambda');
ok(xq9.includes('getAndUpdate(new as1(bs1Var2.c.get() - 1))'),
  'xq9 dual-counter sync (non-transient)');
ok(xq9.includes('bs1Var.c.getAndIncrement()'), 'xq9 counter increment');
ok(xq9.includes('rh8.b(bs1Var.c.getAndIncrement(), bs1Var.a)'),
  'xq9 rh8.b(counter,site) -> qo5');
ok(xq9.includes('aVarA.j(0, rh8.O(qo5Var, aVarA))'), 'xq9 sdf field0 = qo5');
ok(/zq9\.e\(this\.d, qo5VarB, ceeVar, this\.e, null/.test(xq9),
  'xq9 zq9.e envelope (clientTime, null serverTime)');
ok(xq9.includes('new tmf(xgbVar.I)'), 'xq9 xgb -> tmf wrap');
ok(xq9.includes('sdf sdfVar2 = new sdf()') && xq9.includes('aVarA.C(2)'),
  'xq9 sdf C(2) TransientInteraction');

// ---- 调用形态 ----
const callers = ['te0.java', 'kp5.java', 'nx6.java', 'zm7.java'];
for (const f of callers) {
  ok(rd(f).includes('new wq9('), `${f} uses new wq9(...)`);
}
ok(rd('te0.java').includes(', null, false, null, 30)'), 'wq9 mask 30 call form');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
