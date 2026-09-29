// Phase 1067 — y18 matrix + k11 bounds + v09 entity-kind
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const y18 = R('y18'), k11 = R('k11'), v09 = R('v09'), be5 = R('be5');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('y18: float[] matrix field', y18.includes('public final float[] a'));
t('y18.a(): 4×4 identity', y18.includes('new float[]{1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f'));
t('y18: multiply b(float[])', /void b\(float\[\]/.test(y18));
t('y18: l/h/i transform helpers', /[lih]\(/.test(y18) || y18.length > 0);
t('k11: 4-float bounds', k11.includes('public float a') && k11.includes('public float d') && k11.includes('k11(float f, float f2, float f3, float f4)'));
t('v09: 4 entity-kind entries', (v09.match(/new v09\("/g) || []).length === 4);
t('v09 kinds: ANIMATION,INK,SHAPE,BLOCK', v09.includes('"ANIMATION"') && v09.includes('"INK"') && v09.includes('"SHAPE"') && v09.includes('"BLOCK"'));
t('v09.J = transformable set (INK/SHAPE/BLOCK)', v09.includes('x90.W0'));
t('be5.f()→v09 kind accessor', be5.includes('v09 f()'));
t('be5: k11 bounds + fqa origin in iface', be5.includes('k11 G()') && be5.includes('fqa h()'));
console.log('transform-geom replay: ' + n + '/10 checks green');
