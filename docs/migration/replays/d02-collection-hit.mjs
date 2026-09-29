// Phase 1083 — ba6.M parent-collection + O hit-test + P filter
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ba6 = R('ba6');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ba6.M(v69,qo5)→o4c', ba6.includes('o4c M(v69 v69Var, qo5 qo5Var)'));
t('ba6.M: null→v69.o() default e4c', ba6.includes('return e4cVarO') && ba6.includes('v69Var.o()'));
t('ba6.M: tombstone K(id,j)→null', ba6.includes('K(qo5Var, al2VarJ)'));
t('ba6.M: oy0 via qja.r().I / uia.i()', ba6.includes('qjaVarR.I.get(qo5Var)') && ba6.includes('uiaVarI.get(qo5Var)'));
t('ba6.M: xhe→cie.c / hp5→d member collection', ba6.includes('((cie) ((xhe) oy0Var)).c') && ba6.includes('((hp5) oy0Var).d'));
t('ba6.O: y-offset hit-test', ba6.includes('ehf O(float f, List list)') && ba6.includes('fC > f'));
t('ba6.O: accumulates bmb height', ba6.includes('bmbVar.d().c() + f2'));
t('ba6.O: ehf{index,id,offset}', ba6.includes('new ehf(Integer.valueOf(i), fw4Var.a'));
t('ba6.P: bounds filter', ba6.includes('List P(k11 k11Var, List list)') && ba6.includes('k11Var.b'));
t('fw4 item {bmb,a}', ba6.includes('fw4Var.b') && ba6.includes('fw4Var.a'));
console.log('collection-hit replay: ' + n + '/10 checks green');
