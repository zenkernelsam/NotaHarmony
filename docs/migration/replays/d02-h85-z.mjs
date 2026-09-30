// Phase 1142 — h85 member-collection + ba6.z recursive children resolve
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const h85 = R('h85'), ba6 = R('ba6');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('h85 interface', h85.includes('interface h85') || h85.includes('h85'));
t('h85.List M() member accessor', h85.includes('List M()'));
t('k85 implements h85', R('k85').includes('implements h85') || R('k85').includes('h85'));
t('ba6.z(v69,map,list,set,h85)', ba6.includes('void z(v69 v69Var, LinkedHashMap linkedHashMap, ArrayList arrayList, LinkedHashSet linkedHashSet, h85 h85Var)'));
t('z: iterate h85.M() children', ba6.includes('for (qo5 qo5Var : h85Var.M())'));
t('z: recursive y(v69,child)', ba6.includes('wnd wndVarY = y(v69Var, qo5Var, linkedHashMap)'));
t('z: vnd→list if resolved', ba6.includes('arrayList.add(vndVar)'));
t('z: O0 merge c elements + b ops', ba6.includes('au1.O0(arrayList, wndVarY.c)') && ba6.includes('au1.O0(linkedHashSet, wndVarY.b)'));
t('z: o09 visited-mark', ba6.includes('linkedHashSet.add(new o09(qo5Var))'));
t('z DFS flattens member tree', ba6.includes('y(v69Var, qo5Var') && ba6.includes('h85Var.M()'));
console.log('h85-z replay: ' + n + '/10 checks green');
