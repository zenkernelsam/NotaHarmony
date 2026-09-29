// Phase 1061 — shape definition sub-tables (z5c.a0 factory)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const z5c = R('z5c'), uf7 = R('uf7'), pra = R('pra'), oz8 = R('oz8'), pz8 = R('pz8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('z5c.a0: factory on z4d ordinal', z5c.includes('cee a0(z4d z4dVar)') && z5c.includes('z4dVar.ordinal()'));
t('a0: NONE→null', /iOrdinal == 0[\s\S]{0,40}return null/.test(z5c));
t('a0: LINE→uf7, POLYGON→pra, NORMAL_SHAPE→oz8', z5c.includes('new uf7()') && z5c.includes('new pra()') && z5c.includes('new oz8()'));
t('a0: unreachable default', /oz8\(\);[\s\S]{0,80}o14\.t\(\)/.test(z5c));
t('uf7 Line: bezier+arrowHead', uf7.includes('Line(start=') && uf7.includes('controlPoint1=') && uf7.includes('controlPoint2=') && uf7.includes('end=') && uf7.includes('arrowHead='));
t('pra Polygon: points vector', pra.includes('Polygon(points=') && pra.includes('lv2.a0(this)'));
t('oz8 NormalShape{type,size}', oz8.includes('NormalShape(type=') && oz8.includes('size='));
t('oz8: type→pz8 via byte bounds-check', oz8.includes('pz8.a()') && oz8.includes('get(0)'));
t('pz8: enum + ELLIPSE', pz8.includes('ELLIPSE') && pz8.includes('nz3'));
t('defs are cee tables', [uf7, pra, oz8].every(s => s.includes('extends cee')));
t('le8.definition via z5c.w', R('le8').includes('z5c.w(this)') && z5c.includes('cee w(le8 '));
console.log('shape-defs replay: ' + n + '/11 checks green');
