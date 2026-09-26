// Phase 865 — 序列位置标识契约（cxc/exc/nti/oz9/v09）登记回归
// 证据：docs/migration/evidence/phase-865-sequence-position-identity.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'note/src/main/ets/data/OperationIdentity.ets';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

// ---- cxc：12 字节内联结构 ----
const cxc = readFileSync(join(SRC, 'cxc.java'), 'utf8');
ok(cxc.includes('extends xwd implements ka4, exc'), 'cxc = xwd struct implementing exc');
ok(cxc.includes('this.J.getShort(this.I)'), 'cxc site = short @+0');
ok(cxc.includes('this.J.getInt(this.I + 4)'), 'cxc timestamp = int @+4');
ok(cxc.includes('this.J.getInt(this.I + 8)'), 'cxc index = int @+8');
ok(cxc.includes('return d();') || /a1\(\)[\s\S]{0,40}d\(\)/.test(cxc), 'cxc a1() = timestamp');

// ---- nti 构造 ----
const nti = readFileSync(join(SRC, 'nti.java'), 'utf8');
ok(nti.includes('public static cxc f(short s, int i, int i2)'), 'nti.f(site,ts,index) builder');
ok(nti.includes('aVarA.t(4, 12)'), 'nti.f builds 12-byte align-4 struct');
ok(nti.includes('aVarA.s(2)') && nti.includes('aVarA.y(s)'), 'nti.f pad@2 + site@0');
ok(nti.includes('public static final cxc g(qo5 qo5Var, int i)') &&
   nti.includes('return f(qo5Var.c(), qo5Var.d(), i)'),
  'nti.g = f(opId.site, opId.ts, index)');
ok(nti.includes('ybg.c(cxcVar)'), 'nti.f runs ka4 validation post-build');

// ---- exc.A0 比较器：ts asc → site asc → index DESC ----
const exc = readFileSync(join(SRC, 'exc.java'), 'utf8');
ok(exc.includes('a1() - excVar.a1()'), 'exc.A0 primary key = timestamp (int subtraction)');
ok(exc.includes('(m() & 65535) - (excVar.m() & 65535)'), 'exc.A0 secondary = unsigned-u16 site');
ok(exc.includes('excVar.C() - C()'), 'exc.A0 tie-break = index DESCENDING (other - this)');
ok(!exc.includes('C() - excVar.C()'), 'exc.A0 does NOT use ascending index (trap)');

// ---- wz9 使用点 ----
const wz9 = readFileSync(join(SRC, 'wz9.java'), 'utf8');
ok(wz9.includes('nti.g(uq9Var.l(), i)'), 'wz9 derives page position via nti.g(opId, pageInPayload)');

// ---- oz9 / v09 枚举 ----
const oz9 = readFileSync(join(SRC, 'oz9.java'), 'utf8');
ok(oz9.includes('UNBOOKMARKED((byte) 0)') && oz9.includes('BOOKMARKED((byte) 1)'),
  'oz9 = {UNBOOKMARKED=0, BOOKMARKED=1}');
const v09 = readFileSync(join(SRC, 'v09.java'), 'utf8');
ok(v09.includes('"ANIMATION", 0') && v09.includes('"INK", 1') &&
   v09.includes('"SHAPE", 2') && v09.includes('"BLOCK", 3'),
  'v09 = {ANIMATION,INK,SHAPE,BLOCK}');

// ---- Harmony 等价 ----
const harm = readFileSync(HARM, 'utf8');
ok(harm.includes('interface OriginalSequenceIdentity extends OperationIdentity'),
  'OriginalSequenceIdentity = cxc triple');
ok(harm.includes('seq:${identity.timestamp.toString(16)}:${identity.siteId.toString(16)}:${identity.index.toString(16)}'),
  'encodeOriginalSequenceId = seq:ts:site:index');
ok(harm.includes('exc.A0'), 'comparator cites original exc.A0');
ok(harm.includes('toJavaInt(left.timestamp) - toJavaInt(right.timestamp)) | 0'),
  'ts diff keeps Java int wraparound');
ok(harm.includes('toJavaInt(right.index) - toJavaInt(left.index)) | 0'),
  'index tie-break DESCENDING matches original');
ok(harm.includes('encodeOriginalPageStorageId'), 'page storage id carries sequence identity');
ok(harm.includes('value >= 0x80000000 ? value - 0x100000000'), 'toJavaInt = u32->i32 wrap');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
