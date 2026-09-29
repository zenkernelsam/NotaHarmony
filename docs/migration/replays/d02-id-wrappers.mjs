// Phase 1071 — u09 id union + nti.g page-id synthesis + yq9.a gate
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const u09 = R('u09'), o09 = R('o09'), r09 = R('r09'), nti = R('nti'), yq9 = R('yq9');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('u09: id-union iface + n09 companion', u09.includes('interface u09') && u09.includes('n09 a'));
t('o09: entity-id wraps qo5', o09.includes('implements u09') && o09.includes('public final qo5 b'));
t('r09: page-id wraps cxc', r09.includes('implements u09') && r09.includes('public final cxc b'));
t('nti.g(qo5,i)→cxc', nti.includes('cxc g(qo5 qo5Var, int i)'));
t('nti.g: f(site,logicalTime,seq)', nti.includes('f(qo5Var.c(), qo5Var.d(), i)'));
t('yq9.a: ordinal→category int[]', yq9.includes('int[] a') && yq9.includes('haa.values().length'));
t('yq9.a[25]=1 → DELETE gate', yq9.includes('iArr[25] = 1'));
t('o09/r09: value equality', o09.includes('boolean equals') && r09.includes('boolean equals'));
t('n09 companion exists', R('n09').length > 0);
t('yq9.a: NoSuchFieldError guarded init', yq9.includes('NoSuchFieldError'));
console.log('id-wrappers replay: ' + n + '/10 checks green');
