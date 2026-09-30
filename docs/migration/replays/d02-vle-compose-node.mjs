// Phase 1207 — vle Compose node binding (ry8 LayoutNode / jw6 DrawScope / mv6 LayoutCoordinates)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ry8 = R('ry8.java');
t('ry8 extends dt7 implements l28,mv6,ow9', ry8.includes('extends dt7') && ry8.includes('mv6') && ry8.includes('ow9'));
t('ry8 parent/child ry8 links', ry8.includes('ry8 Z') && ry8.includes('ry8 a0'));
t('ry8 hw6 coordinator', ry8.includes('hw6 W'));
const jw6 = R('jw6.java');
t('jw6 implements no3', jw6.includes('implements no3'));
t('jw6 xd1 draw delegate', jw6.includes('xd1'));
t('jw6 lo3 editor back-ref', jw6.includes('lo3 J'));
t('no3 extends r93 Density', R('no3.java').includes('extends r93'));
const mv6 = R('mv6.java');
t('mv6 LayoutCoordinates A/G/J/i', mv6.includes('mv6 A()') && mv6.includes('cmb J(mv6') && mv6.includes('void i(float[]'));
t('dt7 extends cla', R('dt7.java').includes('extends cla'));
t('hw6 measure/layout coordinator', R('hw6.java').includes('implements') && R('hw6.java').includes('m42'));
console.log('vle-compose-node replay: ' + n + '/10 checks green');
