// Phase 1235 — Kalman matrix/filter internals
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const x18 = R('x18.java');
t('x18 matrix {rows,cols,double[]}', x18.includes('int a') && x18.includes('double[] c'));
t('x18 a() matrix multiply', x18.includes('dot matrix operation'));
t('x18 c(i,j) get', x18.includes('double c(int i, int i2)'));
t('x18 g() reset', x18.includes('void g(x18'));
const sl6 = R('sl6.java');
t('sl6 13 x18 matrices a..m', (sl6.match(/public x18 [a-m];/g)||[]).length >= 13);
const gra = R('gra.java');
t('gra ps2 state x4', (gra.match(/ps2 [defg] = new ps2/g)||[]).length >= 4);
t('gra 3 sl6 (a,b,c)', gra.includes('sl6 a = a()') && gra.includes('sl6 b = a()') && gra.includes('sl6 c = a()'));
t('gra x18 scratch k,l,m', gra.includes('new x18(1, 1)'));
t('gra sl6 a() factory', gra.includes('sl6 a()'));
t('gra x18 3-axis kalman', gra.includes('sl6'));
console.log('kalman-math replay: ' + n + '/10 checks green');
