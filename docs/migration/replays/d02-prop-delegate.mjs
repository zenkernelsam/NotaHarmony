// Phase 1146 — xj2.v/w delegated-property getters + fl6/w1b + yy3.E
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const xj2 = R('xj2'), l85 = R('l85'), k85 = R('k85'), yy3 = R('yy3');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('xj2.v(yc6,fl6)→Object', xj2.includes('Object v(yc6 yc6Var, fl6 fl6Var)'));
t('xj2.v returns yc6.K', xj2.includes('return yc6Var.K'));
t('xj2.w(fqb,fl6)→Object', xj2.includes('Object w(fqb fqbVar, fl6 fl6Var)'));
t('xj2.w returns fqb.b (reg value)', xj2.includes('return fqbVar.b'));
t('w1b PropertyReference descriptor', k85.includes('new w1b(k85.class'));
t('k85 $$delegatedProperties fl6[]', k85.includes('fl6[] d'));
t('l85 M() via xj2.v(d,h[0])', l85.includes('xj2.v(this.d, h[0])'));
t('l85 "members" delegate', l85.includes('"members"'));
t('yy3.E() sub-index iface', yy3.includes('int E()'));
t('xj2.x(yc4)→m20 also exists', xj2.includes('m20 x(yc4'));
console.log('prop-delegate replay: ' + n + '/10 checks green');
