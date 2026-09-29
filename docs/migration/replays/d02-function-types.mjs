// Phase 1094 — Kotlin Function* layer xx4/ix4/wx4/kkf/mha
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ix4 = R('ix4'), wx4 = R('wx4'), xx4 = R('xx4'), ba6 = R('ba6'), kkf = R('kkf');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ix4 extends xx4 (Function1)', ix4.includes('extends xx4'));
t('ix4.invoke(Object) 1-arg', ix4.includes('Object invoke(Object obj)'));
t('wx4 extends xx4 (Function2)', wx4.includes('extends xx4'));
t('wx4.invoke(Object,Object) 2-arg', wx4.includes('Object invoke(Object obj, Object obj2)'));
t('xx4 = Function base iface', xx4.length > 0 && xx4.includes('interface'));
t('ba6.L(wx4,ix4)→mha', ba6.includes('mha L(wx4 wx4Var, ix4 ix4Var)'));
t('ba6.L: kkf.w(1,ix4) arity check', ba6.includes('kkf.w(1, ix4Var)'));
t('ba6.L: as0 wraps Function2', ba6.includes('new as0(wx4Var, 4)'));
t('ba6.L: mha(7,as0,ix4) flow', ba6.includes('new mha(7, as0Var, ix4Var)'));
t('kkf.w arity-coerce helper', kkf.includes('w(') || kkf.includes('ix4'));
console.log('function-types replay: ' + n + '/10 checks green');
