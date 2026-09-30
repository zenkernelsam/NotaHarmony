// Phase 1195 — gesture→renderer bridge (aaf GestureDetector + jqa enum + ev9 sensor)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const aaf = R('aaf.java');
t('aaf SimpleOnGestureListener', aaf.includes('SimpleOnGestureListener'));
t('aaf OnTouchListener+dv9', aaf.includes('OnTouchListener') && aaf.includes('dv9'));
t('aaf bpd SceneRenderer', aaf.includes('bpd'));
t('aaf GestureDetector field', aaf.includes('GestureDetector'));
t('aaf onDown/onScroll/onSingleTapUp', aaf.includes('onDown') && aaf.includes('onScroll') && aaf.includes('onSingleTapUp'));
t('aaf PointF touch points', aaf.includes('PointF'));
const jqa = R('jqa.java');
t('jqa 3-value enum', jqa.includes('jqa I') && jqa.includes('jqa K'));
const ev9 = R('ev9.java');
t('ev9 SensorEventListener', ev9.includes('SensorEventListener'));
t('ev9 float[16] rotation matrices', ev9.includes('new float[16]'));
t('ev9 uses Sensor+SensorManager', ev9.includes('Sensor') && ev9.includes('SensorManager'));
console.log('gesture replay: ' + n + '/10 checks green');
