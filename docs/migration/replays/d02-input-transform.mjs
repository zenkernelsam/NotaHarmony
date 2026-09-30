// Phase 1261 — a46/bg4/d28/nv1/z36 InputTransformation
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const a46 = R('a46.java');
t('a46 InputTransformation iface i(dle)', a46.includes('interface a46') && a46.includes('void i(dle'));
const bg4 = R('bg4.java');
t('bg4{a46 a,b} then chain', bg4.includes('a46 a') && bg4.includes('a46 b'));
t('bg4 i() a.then(b)', bg4.includes('void i(dle') && bg4.includes('a.i(') || bg4.includes('a46Var.i'));
const d28 = R('d28.java');
t('d28 maxLength(6)', d28.includes('InputTransformation.maxLength(6)'));
t('d28 i(dle) transform', d28.includes('void i(dle'));
const nv1 = R('nv1.java');
t('nv1 a46 filter', nv1.includes('implements a46') && nv1.includes('void i(dle'));
const z36 = R('z36.java');
t('z36 passthrough singleton', z36.includes('z36 a = new z36()'));
t('z36 a46 impl', z36.includes('implements a46'));
const bg4Full = R('bg4.java');
t('bg4 a46 impl', bg4Full.includes('implements a46'));
t('bg4 h(xvc) semantics', bg4Full.includes('void h(xvc'));
console.log('input-transform replay: ' + n + '/10 checks green');
