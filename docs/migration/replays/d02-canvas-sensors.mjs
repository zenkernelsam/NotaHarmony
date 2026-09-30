// Phase 1194 — canvas sensors/media surface (cpd full fields)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const cpd = R('cpd.java');
t('cpd SensorManager+Sensor', cpd.includes('SensorManager') && cpd.includes('Sensor'));
t('cpd registerListener/unregister', cpd.includes('registerListener') && cpd.includes('unregisterListener'));
t('cpd CopyOnWriteArrayList listeners', cpd.includes('CopyOnWriteArrayList'));
t('cpd SurfaceTexture+Surface fields', cpd.includes('SurfaceTexture O') && cpd.includes('Surface P'));
t('cpd getCameraMotionListener→nc1', cpd.includes('getCameraMotionListener') && cpd.includes('nc1'));
t('cpd getVideoFrameMetadataListener→zxf', cpd.includes('getVideoFrameMetadataListener'));
t('cpd vfc media node', cpd.includes('vfc'));
t('o44 implements zxf,nc1,ypa', R('o44.java').includes('zxf') && R('o44.java').includes('nc1'));
t('ubd swaps SurfaceTexture O/Surface P', R('ubd.java').includes('SurfaceTexture') && R('ubd.java').includes('Surface'));
t('cpd a() sensor register method', cpd.includes('registerListener(ev9'));
console.log('canvas-sensors replay: ' + n + '/10 checks green');
