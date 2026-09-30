// Phase 1140 — e0a merge plan + ba6.y entity resolver
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const e0a = R('e0a'), v69 = R('v69'), wnd = R('wnd');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('e0a{ArrayList a, LinkedHashSet b}', e0a.includes('final ArrayList a') && e0a.includes('final LinkedHashSet b'));
t('v69.g(List,map)→e0a', v69.includes('e0a g(List list, LinkedHashMap linkedHashMap)'));
t('g: iterate entity-key union', v69.includes('(qo5) it.next()'));
t('g: ba6.y resolve op→wnd', v69.includes('ba6.y(this, qo5Var, linkedHashMap)'));
t('g: au1.O0 addAll w.c', v69.includes('au1.O0(arrayList, wndVarY.c)'));
t('g: vnd resolved→a / op→b', v69.includes('arrayList.add(vndVar)') && v69.includes('linkedHashSet.add(qo5Var)'));
t('g: return new e0a(list,set)', v69.includes('new e0a(arrayList, linkedHashSet)'));
t('wnd{vnd a, c list} result', wnd.includes('vnd') && wnd.includes('class wnd'));
t('ba6.y resolver exists', R('ba6').includes('wnd y(v69 v69Var'));
t('yc6.z consumes e0a.b', R('yc6').includes('e0aVar.b'));
console.log('merge-plan replay: ' + n + '/10 checks green');
