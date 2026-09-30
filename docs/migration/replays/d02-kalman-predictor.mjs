// Phase 1234 — bi8 multi-pointer Kalman predictor
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const bi8 = R('bi8.java');
t('bi8 MultiPointerPredictor log', bi8.includes('MultiPointerPredictor'));
t('bi8 SparseArray a per-pointer', bi8.includes('SparseArray a'));
t('bi8 gdd(pointerId,toolType)', bi8.includes('new gdd(this.b, pointerId, motionEvent.getToolType'));
t('bi8 b(int) predict ev', bi8.includes('MotionEvent b(int i)'));
t('bi8 remove on up', bi8.includes('sparseArray.remove(pointerId)'));
const gdd = R('gdd.java');
t('gdd 3-axis sl6 Kalman (gra.a/b/c)', (gdd.match(/sl6Var/g)||[]).length >= 6);
t('gdd x18.g filter update', gdd.includes('x18.g'));
t('gdd findPointerIndex/toolType', gdd.includes('findPointerIndex') && gdd.includes('toolType'));
const mf8 = R('mf8.java');
t('mf8 iface a(ev),b()->ev', mf8.includes('MotionEvent b()'));
const tl6 = R('tl6.java');
t('tl6{bi8,uta} consumer', tl6.includes('bi8 a') && tl6.includes('uta b'));
console.log('kalman-predictor replay: ' + n + '/10 checks green');
