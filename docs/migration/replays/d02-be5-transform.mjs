// Phase 900 — be5 变换契约 + y18 矩阵回归
// 证据：docs/migration/evidence/phase-900-be5-transform.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const be5 = rd('be5.java');
const qsa = rd('qsa.java');
const y18 = rd('y18.java');

// ---- be5 接口 ----
ok(be5.includes('public interface be5'), 'be5 interface');
ok(be5.includes('k11 G()') && be5.includes('qed b()') &&
   be5.includes('v09 f()') && be5.includes('fqa h()') &&
   be5.includes('cxc i()') && be5.includes('Float j()'),
  'be5 six accessors {bounds,scale,kind,origin,page,rotation}');
ok(be5.includes('default float[] P(fqa fqaVar)'), 'be5.P default transform');
ok(be5.includes('default k11 y(k11 k11Var)'), 'be5.y bounds transform');
ok(be5.includes('y18.l(fArrA, fqaVar.c(), fqaVar.d())'),
  'be5.P translate step');
ok(be5.includes('y18.h(ldj.t2(fJ.floatValue()), fArrA)'),
  'be5.P rotate step (deg->rad)');
ok(be5.includes('y18.i(fArrA, qedVarB.d(), qedVarB.c())'),
  'be5.P scale step');
ok(be5.includes('y18.d(P(null), yk8Var)'), 'be5.y rect transform');

// ---- qsa applier ----
ok(qsa.includes('public interface qsa extends be5') &&
   qsa.includes('void d(uq9 uq9Var, ie8 ie8Var)'),
  'qsa extends be5 + ModifyPosition apply');

// ---- y18 矩阵 ----
ok(y18.includes('public static float[] a()'), 'y18.a identity');
ok(y18.includes('1.0f, 0.0f, 0.0f, 0.0f') && y18.includes('float[16]') ||
   y18.includes('new float[]{1.0f'), 'y18.a 4x4 identity literal');
ok(y18.includes('public static final void l(float[] fArr, float f, float f2)'),
  'y18.l translate');
ok(y18.includes('fArr[12] = f3') && y18.includes('fArr[13] = f4') &&
   y18.includes('fArr[14] = f5'), 'y18.l updates translation column');
ok(y18.includes('fArr.length < 16'), 'y18 16-element guard');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
