// Phase 889 — sw9=PDFAsset + zwd 结构派发回归
// 证据：docs/migration/evidence/phase-889-pdfasset-sw9.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const sw9 = rd('sw9.java');
const j7j = rd('j7j.java');
const zwd = rd('zwd.java');
const lv2 = rd('lv2.java');

// ---- sw9 = PDFAsset ----
ok(sw9.includes('public final class sw9 extends cee implements ka4'), 'sw9 cee+ka4');
ok(sw9.includes('PDFAsset(metadata='), 'sw9 toString = PDFAsset');
ok(sw9.includes('layoutBehavior=') && sw9.includes('totalPageCount=') &&
   sw9.includes('pagesConsumed=') && sw9.includes('pageOffset=') &&
   sw9.includes('cropBoxes='), 'sw9 six named fields');
ok(sw9.includes('public final xw9 l()') && sw9.includes('public final wa0 m()'),
  'sw9 l()->xw9, m()->wa0');
ok(sw9.includes('public final void j(int i, qed qedVar)') &&
   sw9.includes('public final int k()'), 'sw9 cropBoxes = qed vector accessor');
ok(sw9.includes('lv2.v(this)'), 'sw9 cropBoxes via lv2.v');
ok(sw9.includes('mmf.a(p())') && sw9.includes('mmf.a(o())') &&
   sw9.includes('mmf.a(n())'), 'sw9 page counts mmf-wrapped x3');

// ---- j7j.c 写侧 ----
ok(j7j.includes('int iC = k1j.c(wa0VarM, aVar)'), 'j7j.c f0 = wa0 via k1j.c');
ok(j7j.includes('aVar.c(1, b, 2)'), 'j7j.c f1 = xw9 byte default 2');
ok(j7j.includes('aVar.e(2, iP, 1)') && j7j.includes('aVar.e(3, iO, 1)') &&
   j7j.includes('aVar.e(4, iN, 0)'), 'j7j.c f2/3/4 int defaults 1/1/0');
ok(j7j.includes('aVar.h(5, iIntValue)') && j7j.includes('aVar.D(8, iK, 4)'),
  'j7j.c f5 = 8B-elem struct vector');
ok(j7j.includes('zwd.a((xwd) wj9Var.invoke'), 'j7j.c vector elems via zwd.a');
ok(j7j.includes('aVar.z(iN2, 4)') && j7j.includes('aVar.z(iN2, 14)'),
  'j7j.c required-field marks');
ok(j7j.includes('Got negative length'), 'j7j.c negative-length guard');

// ---- zwd.a 派发 ----
ok(zwd.includes('public static final int a(xwd xwdVar, a aVar)'), 'zwd.a dispatch');
ok(zwd.includes('npbVar.b(cls)') && zwd.includes('wx4 wx4Var = (wx4) map.get'),
  'zwd.a registry-map lookup');
ok(zwd.includes('rgc.b('), 'zwd.a fail-closed rgc.b on missing');

// ---- lv2.v ----
ok(lv2.includes('public static final List v(sw9 sw9Var)'), 'lv2.v materializer');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
