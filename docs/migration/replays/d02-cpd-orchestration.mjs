// Phase 1230 — cpd GL canvas orchestration
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const cpd = R('cpd.java');
t('cpd extends GLSurfaceView', cpd.includes('extends GLSurfaceView'));
t('cpd sensor 15 fallback 11', cpd.includes('getDefaultSensor(15)') && cpd.includes('getDefaultSensor(11)'));
t('cpd vfc N media node', cpd.includes('new vfc()'));
t('cpd bpd renderer + aaf touch', cpd.includes('new bpd(this, vfcVar)') && cpd.includes('new aaf(context, bpdVar)'));
t('cpd ev9(display,aaf,bpd)', cpd.includes('new ev9(') && cpd.includes('aafVar, bpdVar'));
t('cpd EGL 2.0', cpd.includes('setEGLContextClientVersion(2)'));
t('cpd a() sensor gate Q&&R', cpd.includes('this.Q && this.R') && cpd.includes('registerListener'));
t('cpd getCameraMotionListener->N', cpd.includes('getCameraMotionListener()') && cpd.includes('getVideoFrameMetadataListener()'));
t('cpd setDefaultStereoMode->N.S', cpd.includes('setDefaultStereoMode') && cpd.includes('this.N.S'));
t('cpd onDetached b94 teardown', cpd.includes('onDetachedFromWindow') && cpd.includes('b94(this, 19)'));
console.log('cpd-orchestration replay: ' + n + '/10 checks green');
