// Phase 1229 — ev9 camera-motion sensor
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ev9 = R('ev9.java');
t('ev9 implements SensorEventListener', ev9.includes('implements SensorEventListener'));
t('ev9 getRotationMatrixFromVector', ev9.includes('getRotationMatrixFromVector'));
t('ev9 Display.getRotation remap', ev9.includes('getRotation()') && ev9.includes('remapCoordinateSystem'));
t('ev9 getOrientation', ev9.includes('getOrientation'));
t('ev9 d[2] roll', ev9.includes('fArr4[2]'));
t('ev9 rotateM 90 X', ev9.includes('Matrix.rotateM') && ev9.includes('90.0f'));
t('ev9 baseline m40.d', ev9.includes('m40.d(fArr5, fArr2)') && ev9.includes('this.g = true'));
t('ev9 multiplyMM relative', ev9.includes('Matrix.multiplyMM'));
t('ev9 dv9[] f listeners', ev9.includes('dv9[] f'));
t('ev9 f[i].a(roll,matrix)', ev9.includes('.a(f, fArr2)'));
console.log('ev9-camera-motion replay: ' + n + '/10 checks green');
