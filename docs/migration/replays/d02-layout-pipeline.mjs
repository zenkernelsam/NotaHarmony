// Phase 1134 — layout pipeline mr5/or5/nr5/k4c
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const mr5 = R('mr5'), or5 = R('or5'), nr5 = R('nr5'), k4c = R('k4c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('mr5{Object,int} cursor', mr5.includes('final Object a') && mr5.includes('final int b'));
t('or5 implements rr5,nr5', or5.includes('implements rr5, nr5'));
t('or5 {sy8,bka} builder fields', or5.includes('sy8 a') && or5.includes('bka c'));
t('or5 builder() throws Already-builder', or5.includes('Already a builder'));
t('nr5 extends mxc', nr5.includes('interface nr5 extends mxc'));
t('nr5.a(mr5)→mr5 step', nr5.includes('mr5 a(mr5'));
t('k4c implements j4c host', k4c.includes('implements j4c'));
t('k4c {l4c,or5,mha}', k4c.includes('l4c a') && k4c.includes('or5 b') && k4c.includes('mha c'));
t('k4c mha(10) channel', k4c.includes('new mha(10)'));
t('k4c.e flag + d param', k4c.includes('boolean e') && k4c.includes('double d'));
console.log('layout-pipeline replay: ' + n + '/10 checks green');
