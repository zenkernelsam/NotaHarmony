// Phase 1136 — au1 collections facade + *nb Ref capture types
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const au1 = R('au1'), mnb = R('mnb'), hnb = R('hnb'), knb = R('knb');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('au1.c1 = first() (throw empty)', au1.includes('Object c1(List list)') && au1.includes('list.isEmpty()'));
t('au1.e1 = firstOrNull(iterable)', au1.includes('Object e1(Iterable iterable)'));
t('au1.f1 = firstOrNull(list)', au1.includes('Object f1(List list)'));
t('au1.g1 = getOrNull(i,list)', au1.includes('Object g1(int i, List list)') && au1.includes('i >= list.size()'));
t('au1.h1 = intersect→LinkedHashSet', au1.includes('LinkedHashSet h1(Iterable'));
t('mnb = Ref.ObjectRef', mnb.includes('class mnb') && mnb.includes('Object I'));
t('hnb = Ref.BooleanRef', hnb.includes('class hnb') && hnb.includes('boolean I'));
t('knb = Ref.IntRef', knb.includes('class knb') && knb.includes('int I'));
t('*nb Serializable', mnb.includes('Serializable') && hnb.includes('Serializable') && knb.includes('Serializable'));
t('e4c uses mnb/knb captures in DFS', R('e4c').includes('mnbVar.I') && R('e4c').includes('knbVar.I'));
console.log('stdlib-refs replay: ' + n + '/10 checks green');
