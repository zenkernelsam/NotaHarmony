// Phase 1089 — exc text-anchor triple order + kci.b insert build
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const exc = R('exc'), kci = R('kci');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('exc extends Comparable', exc.includes('interface exc extends Comparable'));
t('exc A0: primary a1()-a1()', exc.includes('a1() - excVar.a1()'));
t('exc A0: site (m&0xffff)', exc.includes('(m() & 65535) - (excVar.m() & 65535)'));
t('exc A0: C() REVERSED (o.C-C)', exc.includes('excVar.C() - C()'));
t('exc: a1()+m()+C() accessors', exc.includes('int a1()') && exc.includes('short m()') && exc.includes('int C()'));
t('kci.b(exc,str,qo5)→f46', kci.includes('f46 b(exc excVar, String str, qo5 qo5Var)'));
t('kci.b: slot0 sg5.f(exc) location', kci.includes('sg5.f(aVarA, excVar)'));
t('kci.b: slot2 rh8.O(qo5) textField', kci.includes('rh8.O(qo5Var, aVarA)'));
t('kci.b: FlatBuffers table build', kci.includes('new f46()'));
t('exc: 3-key total order chain', exc.includes('if (iA1 != 0)') && exc.includes('iM != 0 ? iM :'));
console.log('text-anchor replay: ' + n + '/10 checks green');
