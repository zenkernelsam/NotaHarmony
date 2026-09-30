// Phase 1141 — ba6.y per-op entity resolver
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ba6 = R('ba6'), wnd = R('wnd');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ba6.y(v69,qo5,map)→wnd', ba6.includes('wnd y(v69 v69Var, qo5 qo5Var, LinkedHashMap'));
t('y: ny3 bounds service', ba6.includes('ny3 ny3Var = v69Var.c'));
t('y: K tombstone→h85 children', ba6.includes('if (K(qo5Var, v69Var.j()))') && ba6.includes('(h85) v69Var.k().get(qo5Var)'));
t('y: return wnd(null,set,list) unresolved', ba6.includes('new wnd(null, linkedHashSet, arrayList)'));
t('y: r().I qja lookup first', ba6.includes('v69Var.r().I.get(qo5Var)'));
t('y: l()→s06 + p()→m4d + i() chain', ba6.includes('(s06) v69Var.l().get(qo5Var)') && ba6.includes('(m4d) v69Var.p().get(qo5Var)') && ba6.includes('v69Var.i().get(qo5Var)'));
t('y: be5 transformable branch', ba6.includes('ly3Var instanceof be5'));
t('y: yy3.E() sub-index', ba6.includes('((yy3) ly3Var).E()'));
t('y: ny3.e/a sub-bounds cache', ba6.includes('ny3Var.e(ly3Var.getId(), numValueOf.intValue())') && ba6.includes('ny3Var.a(ly3Var.getId(), numValueOf.intValue(), k11VarE)'));
t('y: ba6.z h85-children helper', ba6.includes('z(v69Var, linkedHashMap, arrayList, linkedHashSet'));
console.log('ba6-y replay: ' + n + '/10 checks green');
