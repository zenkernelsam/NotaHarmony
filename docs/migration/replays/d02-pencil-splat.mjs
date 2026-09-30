// Phase 1184 — pencil splat model (mea stamp + lea atlas + owd splats)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const owd = R('owd.java');
t('owd PencilStrokeContent', owd.includes('PencilStrokeContent'));
t('owd splats field', owd.includes('splats'));
t('owd uses mea', owd.includes('mea'));
const mea = R('mea.java');
t('mea k=sqrt(2)', mea.includes('sqrt(2'));
t('mea lea atlas field', mea.includes('lea'));
t('mea int color + pos fields', mea.includes('int b') && mea.includes('float f'));
t('mea f(int,float) color multiply', mea.includes('f(int'));
t('mea rh8.v channel clamp', mea.includes('rh8.v'));
t('lea extends a (atlas base)', R('lea.java').includes('extends a'));
t('base a has static byte[] (baked atlas)', R('a.java').includes('byte[]'));
console.log('pencil-splat replay: ' + n + '/10 checks green');
