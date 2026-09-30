// Phase 1266 — ry8/dt7/hw6/jw6 layout/draw internals
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ry8 = R('ry8.java');
t('ry8 extends dt7 mv6', ry8.includes('extends dt7 implements l28, mv6, ow9'));
t('ry8 hw6 coordinator + parent/child', ry8.includes('hw6 W') && ry8.includes('ry8 Z') && ry8.includes('ry8 a0'));
t('ry8 r93+nv6 density/direction', ry8.includes('r93 e0') && ry8.includes('nv6 f0'));
const dt7 = R('dt7.java');
t('dt7 extends cla dg8+s28', dt7.includes('extends cla implements dg8, s28'));
t('dt7 et7 T + E0(ry8)', dt7.includes('et7 T') && dt7.includes('E0(ry8'));
const hw6 = R('hw6.java');
t('hw6 Undefined intrinsics sentinel', hw6.includes('Undefined intrinsics block and it is required'));
t('hw6 constraints L + parent Q', hw6.includes('long L') && hw6.includes('hw6 Q'));
const jw6 = R('jw6.java');
t('jw6 implements no3 DrawScope', jw6.includes('implements no3'));
t('jw6 xd1 delegate + lo3 J', jw6.includes('xd1 I') && jw6.includes('lo3 J'));
t('jw6 drawCircle/drawLine Q0/S0', jw6.includes('Q0(f31') && jw6.includes('S0(long'));
console.log('layout-draw replay: ' + n + '/10 checks green');
