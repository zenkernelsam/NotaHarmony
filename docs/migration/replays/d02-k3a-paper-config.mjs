// Phase 888 — k3a 纸面配置六字段回归
// 证据：docs/migration/evidence/phase-888-k3a-paper-config.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const fag = rd('fag.java');
const tu1 = rd('tu1.java');
const cmf = rd('cmf.java');
const n3a = rd('n3a.java');
const a79 = rd('a79.java');

// ---- fag.o0 六字段 ----
ok(fag.includes('int o0(a aVar, n3a n3aVar, Float f, Boolean bool, Boolean bool2, hu1 hu1Var, cmf cmfVar)'),
  'fag.o0 six-arg k3a writer');
ok(fag.includes('aVar.C(6)'), 'k3a C(6) fields');
ok(fag.includes('aVar.c(0, n3aVar.I, 0)'), 'f0 = n3a template enum');
ok(fag.includes('aVar.d(1, f.floatValue(), 0.0d)'), 'f1 = float default 0.0');
ok(fag.includes('aVar.a(2, bool.booleanValue(), false)') &&
   fag.includes('aVar.a(3, bool2.booleanValue(), false)'), 'f2/f3 = bool pair');
ok(fag.includes('aVar.j(4, z5c.P(hu1Var, aVar))'), 'f4 = hu1 color via z5c.P');
ok(fag.includes('aVar.c(5, cmfVar.I, 0)'), 'f5 = cmf byte enum');
ok(fag.includes('aVar.l = true') && fag.includes('aVar.l = false'),
  'o0 builder write-mode flag around bools');

// ---- k3a 访问器委托 ----
ok(fag.includes('o0(aVar, k3aVar.k(), k3aVar.n(), k3aVar.l(), k3aVar.m(), k3aVar.j(), k3aVar.o())'),
  'fag.n0 maps k3a k/n/l/m/j/o accessors');

// ---- fag.k 工厂 + 掩码 111 ----
ok(a79.includes('fag.k(null, null, null, (hu1) tu1.a.getValue(), null, 111)'),
  'a79.Q fag.k(hu1 color only, mask 111)');

// ---- tu1 颜色族 ----
ok(tu1.includes('public static final pce a = new pce(new ra(13))'),
  'tu1.a = lazy pce(ra(13)) provider');
ok(tu1.includes('public static final hu1 a(float f, float f2, float f3, float f4)'),
  'tu1.a(r,g,b,a) hu1 ctor');
ok(tu1.includes('public static final hu1 c(int i)') &&
   tu1.includes('public static final hu1 d(Color color)'), 'tu1.c/d hu1 ctors');
ok(tu1.includes('public static final int b(hu1 hu1Var)'), 'tu1.b hu1 -> int');

// ---- cmf/n3a 值层 ----
ok(cmf.includes('public final byte I') && cmf.includes('ba6.w(this.I & 255'),
  'cmf = byte value-class enum');
ok(n3a.includes('LINES((byte) 0)') && n3a.includes('DOTS((byte) 1)') &&
   n3a.includes('GRID((byte) 2)'), 'n3a = LINES/DOTS/GRID');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
