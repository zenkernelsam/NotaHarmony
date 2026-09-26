// Phase 866 — 赢家寄存器契约（fqb/do6/xj2/so5.a/fsi.J）登记回归
// 证据：docs/migration/evidence/phase-866-winner-register-contract.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'note/src/main/ets/data';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- fqb 赢家单元 ----
const fqb = readFileSync(join(SRC, 'fqb.java'), 'utf8');
ok(fqb.includes('public qo5 a') && fqb.includes('public Object b') && fqb.includes('public xgb c'),
  'fqb = {winnerId qo5, winnerValue, winnerClock xgb}');
ok(fqb.includes('this.a = (qo5) yc6Var.J') && fqb.includes('this.b = yc6Var.K') &&
   fqb.includes('this.c = (xgb) yc6Var.L'), 'fqb(yc6) unwraps J/K/L register slots');
ok(fqb.includes('new yc6(this.a, this.b, this.c, 14)'), 'fqb.a() freezes into yc6 discriminant-14');
ok(fqb.includes('so5.a(qo5VarL, qo5Var) > 0'), 'fqb.c() LWW via so5.a op-id compare');
ok(fqb.includes('fsi.J(uq9Var)') && fqb.includes('new xgb('), 'fqb records op wall-clock in xgb');

// ---- do6 / xj2 / vz9 ----
const do6 = readFileSync(join(SRC, 'do6.java'), 'utf8');
ok(do6.includes('static fqb g(yc6 yc6Var, yc6 yc6Var2)'), 'do6.g wraps register as fqb builder');
const xj2 = readFileSync(join(SRC, 'xj2.java'), 'utf8');
ok(xj2.includes('return yc6Var.K'), 'xj2.v reads register winner (.K)');
ok(xj2.includes('return fqbVar.b'), 'xj2.w reads fqb winner value');
ok(xj2.includes('new yc6(obj2, obj, obj2, 14)'), 'xj2.k creates empty register (disc 14)');
const vz9 = readFileSync(join(SRC, 'vz9.java'), 'utf8');
ok((vz9.match(/do6\.g\(yc6Var/g) || []).length >= 3, 'vz9 wraps all three page registers');
ok(vz9.includes('new wz9('), 'vz9 build() freezes into new wz9');

// ---- so5.a op-id 比较器 ----
const so5 = readFileSync(join(SRC, 'so5.java'), 'utf8');
ok(so5.includes('Integer.compareUnsigned(qo5Var.d(), qo5Var2.d())'),
  'so5.a timestamp = UNSIGNED u32 compare');
ok(so5.includes('ba6.w(qo5Var.c() & 65535, qo5Var2.c() & 65535)'),
  'so5.a site = unsigned u16 compare');
ok(!so5.includes('C()'), 'so5.a has no index term (op-ids only)');

// ---- fsi.J 挂钟 ----
const fsi = readFileSync(join(SRC, 'fsi.java'), 'utf8');
ok(fsi.includes('uq9Var.n()') && fsi.includes('uq9Var.k()') && fsi.includes('tmfVarN.I'),
  'fsi.J = serverTime(tmf.I) if present else clientTime');

// ---- Harmony 等价 ----
const oid = readFileSync(join(HARM, 'OperationIdentity.ets'), 'utf8');
ok(oid.includes('left.timestamp < right.timestamp'), 'Harmony ts compare on u32 numbers = unsigned');
ok(oid.includes('left.siteId < right.siteId'), 'Harmony site compare');
const nbpi = readFileSync(join(HARM, 'OriginalNoteBundlePageIdentity.ets'), 'utf8');
ok(nbpi.includes('compareOperationIdentity(operation, state.bookmarkWinner) > 0'),
  'winner overwrite iff new op-id wins (so5.a > 0 semantics)');
ok(nbpi.includes('winner_timestamp') && nbpi.includes('winner_site_id'),
  'winner identity persisted as ts+site columns');
ok(nbpi.includes('name_winner_timestamp') && nbpi.includes('z_index_winner_timestamp'),
  'recording registers (name/segments/z_index) persist winners');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
