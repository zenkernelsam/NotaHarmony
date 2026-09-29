// Phase 1116 — kci.j re-serialize + dbj.c v71 zero-copy + sg5.b scratch
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const kci = R('kci'), dbj = R('dbj'), sg5 = R('sg5');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('kci.j(f46,a) reserialize', kci.includes('int j(f46 f46Var, a aVar)'));
t('kci.j: sg5.b thread-local scratch', kci.includes('sg5.b.get()'));
t('kci.j: h(6,bb)/g(6) string read', kci.includes('f46Var.h(6') && kci.includes('f46Var.g(6)'));
t('kci.j: a.m(bb) string recreate', kci.includes('aVar.m(byteBufferG)'));
t('kci.j: C(3)+h(1) rebuild', kci.includes('aVar.C(3)') && kci.includes('aVar.h(1'));
t('kci.j: j(0,sg5.f)+j(2,rh8.O) re-embed', kci.includes('aVar.j(0, sg5.f(aVar, cxcVarJ)') && kci.includes('aVar.j(2, rh8.O(qo5VarL, aVar)'));
t('kci.j: n() end→offset', kci.includes('int iN = aVar.n()'));
t('dbj.c(CharSequence,a)', dbj.includes('int c(CharSequence charSequence, a aVar)'));
t('dbj.c: v71 fast-path', dbj.includes('charSequence instanceof v71'));
t('dbj.c: v71.f(bb)/e() into scratch', dbj.includes('sg5.b.get()') && dbj.includes('.f(byteBuffer)'));
console.log('op-reserialize replay: ' + n + '/10 checks green');
