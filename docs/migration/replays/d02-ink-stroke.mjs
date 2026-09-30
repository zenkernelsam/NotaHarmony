// Phase 1176 — ink-stroke render model (ka8 stroke + i5g style + t16 InkStyle enum + Path)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const t16 = R('t16.java');
t('t16 is InkStyle enum (VARIABLE_WIDTH)', t16.includes('VARIABLE_WIDTH'));
t('t16 FIXED_WIDTH+DASH+DOTS', t16.includes('FIXED_WIDTH') && t16.includes('DASH') && t16.includes('DOTS'));
t('t16 4-value enum byte ordinals', t16.includes('(byte) 0') && t16.includes('(byte) 3'));
const i5g = R('i5g.java');
t('i5g has int+float+t16', i5g.includes('int a') && i5g.includes('float b') && i5g.includes('t16 c'));
t('i5g has 2 boolean flags', i5g.includes('boolean d') && i5g.includes('boolean e'));
t('i5g accessor c() returns t16', i5g.includes('t16 c()'));
const ka8 = R('ka8.java');
t('ka8 has 2 Paths', ka8.includes('Path a') && ka8.includes('Path d'));
t('ka8 ctor takes i5g style', ka8.includes('i5g i5gVar'));
t('ka8 has List points + Float width', ka8.includes('List') && ka8.includes('Float'));
t('nfe/ofe Path factories', R('nfe.java').includes('new Path()') && R('ofe.java').includes('new Path()'));
console.log('ink-stroke replay: ' + n + '/10 checks green');
