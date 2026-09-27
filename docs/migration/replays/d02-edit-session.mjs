// Phase 883 — tzc/aa9 编辑会话层回归
// 证据：docs/migration/evidence/phase-883-edit-session.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const tzc = rd('tzc.java');
const aa9 = rd('aa9.java');
const zac = rd('zac.java');
const l96 = rd('l96.java');
const sxe = rd('sxe.java');

// ---- tzc 结构 ----
ok(tzc.includes('public final class tzc extends zac'), 'tzc extends zac');
ok(tzc.includes('public tzc(ye9 ye9Var, Function0 function0, ya9 ya9Var, qy3 qy3Var)'),
  'tzc ctor (ye9, Function0, ya9, qy3)');
ok(tzc.includes('Note with unresolved editor site'), 'tzc fail-closed site check');
ok(tzc.includes('public final short O') && tzc.includes('public final bs1 P') &&
   tzc.includes('public final bs1 Q'), 'tzc O site + P/Q dual counters');
ok(tzc.includes('public final yc6 U'), 'tzc U = yc6 LWW registers');
ok(tzc.includes('this.M = new aa9(ya9Var, ttfVarC)'), 'tzc M = aa9(ya9,ttf)');
ok(tzc.includes('this.N = new b40(qy3Var, ye9Var.c())'), 'tzc N = b40(qy3,ttf)');
ok(tzc.includes('dh3.a.H1(1)') && tzc.includes('s01.a(ai2VarH1)'),
  'tzc actor mailbox (ai2 channel)');

// ---- v0 事务流 ----
ok(tzc.includes('public final Object v0(eof eofVar, Map map, ix4 ix4Var, ix4 ix4Var2, ef2 ef2Var)'),
  'tzc.v0 transaction signature');
ok(tzc.includes('fsi.s(this.P, this.Q, System.currentTimeMillis(), ix4Var2)'),
  'v0 -> fsi.s ops build');
ok(tzc.includes('this.M.c(listS, mapB, ix4Var, gzcVar)'), 'v0 -> aa9.c apply');
ok(tzc.includes('public final Object B0(x09 x09Var, List list, fqa fqaVar'),
  'tzc.B0 named mutation');
ok(tzc.includes('public final Object c0(x09 x09Var, List list, cxc cxcVar'),
  'tzc.c0 named mutation (cxc position arg)');

// ---- zac/aa9/l51/k1a ----
ok(zac.includes('public abstract class zac implements Closeable') &&
   zac.includes('public abstract void a()'), 'zac = Closeable actor base');
ok(aa9.includes('public final class aa9 extends zac'), 'aa9 extends zac');
ok(aa9.includes('Method not decompiled: defpackage.aa9.c'), 'aa9.c JADX fail registered');
ok(aa9.includes('l51Var.i(z99Var, k1aVar)'), 'aa9.m -> l51.i(k1a) dispatch');
ok(aa9.includes('new k1a(collection, map)'), 'aa9 wraps collection->k1a command');
ok(sxe.includes('new k1a(new o69(ttfVarR0), rh8.b(mmfVarX2.I, s))'),
  'k1a = {o69 target, rh8.b opId}');

// ---- l96.M bs1 工厂 ----
ok(l96.includes('public static bs1 M(short s)') && l96.includes('return new bs1(0, s);'),
  'l96.M(site) = bs1(0,site) counter factory');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
