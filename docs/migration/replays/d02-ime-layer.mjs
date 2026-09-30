// Phase 1221 — IME/soft-keyboard layer (in6/el8/yla/k6f/eje/qie/yie)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('in6 a(rle) dispatcher', R('in6.java').includes('void a(rle'));
const el8 = R('el8.java');
t('el8 extends s7d+ol4', el8.includes('extends s7d') && el8.includes('ol4'));
t('yla Context+MutableSharedFlow', R('yla.java').includes('Context b') && R('yla.java').includes('fm8.a()'));
const k6f = R('k6f.java');
t('k6f eje session', k6f.includes('eje a'));
t('k6f.a launches rad coroutine', k6f.includes('new rad(') && k6f.includes('xj2.A('));
t('k6f yie via aa6.v token', k6f.includes('aa6.v(ejeVar, zie.b)'));
const eje = R('eje.java');
t('eje extends n73 implements q52,qie', eje.includes('extends n73') && eje.includes('q52') && eje.includes('qie'));
t('eje m/q mv6 geometry', eje.includes('long m(mv6') && eje.includes('cmb q(mv6'));
t('eje V visible + c0 job', eje.includes('this.V') && eje.includes('tqd c0'));
t('hi2 marker iface', R('hi2.java').includes('public interface hi2'));
console.log('ime-layer replay: ' + n + '/10 checks green');
