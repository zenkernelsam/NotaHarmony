// Phase 880 — cxc 位置层（nti/bfj/egh/fsi）回归
// 证据：docs/migration/evidence/phase-880-position-layer.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const FB = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/google/flatbuffers';
const HARM = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const nti = rd('nti.java');
const bfj = rd('bfj.java');
const egh = rd('egh.java');
const fsi = rd('fsi.java');
const a = readFileSync(join(FB, 'a.java'), 'utf8');
const u5j = rd('u5j.java');

// ---- FlatBuffers builder 原语实名 ----
ok(/public final void s\(int i\) \{\s*for \(int i2 = 0; i2 < i; i2\+\+\)/.test(a.replace(/\n/g, ' ')),
  'a.s(int) = pad(i) writes i zero bytes');
ok(a.includes('public final void t(int i, int i2)'), 'a.t = prep(align, bytes)');
ok(a.includes('public final void w(int i)') && a.includes('public final void y(short s)'),
  'a.w=putInt, a.y=putShort');

// ---- nti.X 12B 结构 ----
ok(nti.includes('aVar.t(4, 12)') && nti.includes('aVar.w(iC)') &&
   nti.includes('aVar.w(iD)') && nti.includes('aVar.s(2)') && nti.includes('aVar.y(sC)'),
  'nti.X: prep(4,12) + int+int+pad2+short');
ok(nti.includes('public static final int X(cxc cxcVar, a aVar)'), 'nti.X serializer');
ok(nti.includes('short sC = cxcVar.c()') && nti.includes('int iD = cxcVar.d()') &&
   nti.includes('int iC = cxcVar.C()'), 'cxc fields c()=short, d()/C()=int');

// ---- nti.f 构造器 + nti.g op 派生 ----
ok(nti.includes('public static cxc f(short s, int i, int i2)'), 'nti.f constructor');
ok(nti.includes('public static final cxc g(qo5 qo5Var, int i)') &&
   nti.includes('return f(qo5Var.c(), qo5Var.d(), i);'),
  'nti.g(qo5,i) = f(qo5.c, qo5.d, i) op-anchored position');
ok(nti.includes('ybg.c(cxcVar)'), 'nti.f validates via ybg.c');

// ---- bfj.b 删除感知定位 ----
ok(bfj.includes('public static final cxc b(svb svbVar, int i, Map map)'), 'bfj.b signature');
ok(bfj.includes('svbVar.getOrder().i()'), 'bfj.b reads order list');
ok(bfj.includes('ba6.o(map.get(((swc) obj).getValue()), Boolean.TRUE)'),
  'bfj.b filters map-deleted entries');
ok(bfj.includes('fsi.N(i, arrayList)') && bfj.includes('fsi.N(i, order.i())'),
  'bfj.b fsi.N element pick (both branches)');
ok(bfj.includes('ixc.c(swcVar.d(new hr5()))'), 'bfj.b wraps exc -> ixc.c cxc');

// ---- fsi.N after-anchor ----
ok(fsi.includes('return list.get(i - 1);'), 'fsi.N = list[i-1] after-anchor');
ok(fsi.includes('Cannot insert at a negative index'), 'fsi.N negative guard');
ok(fsi.includes('Unable to find location '), 'fsi.N overflow guard');

// ---- egh.a SeqMove ----
ok(egh.includes('public static lxc a(cxc cxcVar)'), 'egh.a -> lxc');
ok(egh.includes('aVarA.C(1)') && egh.includes('aVarA.j(0, nti.X(cxcVar, aVarA))'),
  'egh.a C(1) field0 = nti.X(cxc)');

// ---- u5j 使用点 ----
ok(u5j.includes('bfj.b(f1aVar.b, i, f1aVar.h)'), 'u5j.i bfj.b page-index anchor');
ok(u5j.includes('egh.a(cxcVarB != null ? cxcVarB : null)'), 'u5j.s egh.a moveTo wrap');

// ---- Harmony 逐字节等价 ----
const enc = readFileSync(join(HARM, 'OriginalInsertTextPayloadEncoder.ets'), 'utf8');
ok(enc.includes('writeU16(bytes, offset, identity.siteId);') &&
   enc.includes('writeU16(bytes, offset + 2, 0);') &&
   enc.includes('writeU32(bytes, offset + 4, identity.timestamp);') &&
   enc.includes('writeU32(bytes, offset + 8, identity.index);'),
  'Harmony writeSequence = {siteId,0,timestamp,index} 12B');
ok(enc.includes('locations.length * 12'), 'Harmony 12-byte stride');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
