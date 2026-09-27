// Phase 882 — op 事务层（fsi.s/vt9/bs1/rh8/rgc/qwc/f8d）回归
// 证据：docs/migration/evidence/phase-882-op-transaction.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const fsi = rd('fsi.java');
const vt9 = rd('vt9.java');
const lv2 = rd('lv2.java');
const rgc = rd('rgc.java');
const ar6 = rd('ar6.java');
const bs1 = rd('bs1.java');
const qwc = rd('qwc.java');
const f8d = rd('f8d.java');

// ---- fsi.s 事务 ----
ok(fsi.includes('public static final List s(bs1 bs1Var, bs1 bs1Var2, long j, ix4 ix4Var)'),
  'fsi.s transaction signature');
ok(fsi.includes('ix4Var.invoke(new xq9(bs1Var2, bs1Var, arrayList, aVar, j))'),
  'fsi.s invokes lambda with xq9 context');
ok(fsi.includes('au1.S1(arrayList)') && fsi.includes('aVar.D(4, iArrS1.length, 4)'),
  'fsi.s uq9 vector build');
ok(fsi.includes('aVar.C(2)') && fsi.includes('aVar.h(0, iO)') && fsi.includes('aVar.i(1, s)'),
  'fsi.s 2-field root {ops, schemaVersion}');
ok(fsi.includes('short s = rgc.a;'), 'fsi.s schemaVersion = rgc.a');
ok(fsi.includes('lv2.U(vt9Var)'), 'fsi.s returns lv2.U(vt9)');
ok(fsi.includes('public static final List t(bs1 bs1Var, bs1 bs1Var2, long j, List list)') &&
   fsi.includes('new pq1(8, list)'), 'fsi.t list variant via pq1');

// ---- vt9 OpsBundle ----
ok(vt9.includes('OpsBundle(ops='), 'vt9 toString = OpsBundle');
ok(vt9.includes('ymf.a(k())'), 'vt9 schemaVersion wrapped in ymf');
ok(vt9.includes('public final uq9 l(uq9 uq9Var, int i)'), 'vt9.l uq9 accessor');
ok(lv2.includes('public static final List U(vt9 vt9Var)') &&
   lv2.includes('vt9Var.l(uq9Var, i2)'), 'lv2.U materializes uq9 vector');

// ---- rgc/ar6 schema 版本 ----
ok(rgc.includes('a = ar6.K.I;'), 'rgc.a = ar6.K.I');
ok(ar6.includes('BLOCKS_AND_SHAPES_POSITION_LOCK'), 'ar6 named feature versions');
ok(ar6.includes('new ar6(15)'), 'ar6.K = current schema v15');

// ---- bs1 计数器 ----
ok(bs1.includes('public final short a') && bs1.includes('public final int b') &&
   bs1.includes('public final AtomicInteger c'), 'bs1 {site,base,AtomicInteger}');
ok(bs1.includes('new AtomicInteger(i)'), 'bs1 atomic current');

// ---- qwc/f8d 树节点 ----
ok(qwc.includes('rh8.b(0, (short) -1)'), 'qwc sentinel qo5(0,-1)');
ok(f8d.includes('SharedNodeData(rawSiteId='), 'f8d = SharedNodeData');
ok(f8d.includes('rawAudioTime=') && f8d.includes('parent='),
  'f8d {siteId,timestamp,audioTime,parent,list}');

// ---- 调用面 ----
ok(rd('tzc.java').includes('fsi.s(this.P, this.Q, System.currentTimeMillis()'),
  'tzc session dual bs1 P/Q');
ok(rd('kzc.java').includes('fsi.t(tzcVar.P, tzcVar.Q') &&
   rd('kzc.java').includes('u5j.i(x09Var, i, 0, 14)'),
  'kzc fsi.t + u5j.i mask 14 (all-defaulted)');
ok(rd('rh8.java').includes('public static qo5 b(int i, short s)'), 'rh8.b qo5 ctor');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
