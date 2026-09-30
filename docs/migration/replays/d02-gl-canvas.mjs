// Phase 1177 — GL note canvas (cpd GLSurfaceView + bpd SceneRenderer MVP chain)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const cpd = R('cpd.java');
t('cpd extends GLSurfaceView', cpd.includes('extends GLSurfaceView'));
t('cpd EGL ES2 context', cpd.includes('setEGLContextClientVersion(2)'));
t('cpd setRenderer(bpd)', cpd.includes('setRenderer(bpd'));
t('cpd wires aaf OnTouchListener', cpd.includes('aaf') && cpd.includes('OnTouchListener'));
t('cpd ev9 display-orientation', cpd.includes('ev9') && cpd.includes('getDefaultDisplay'));
const bpd = R('bpd.java');
t('bpd implements GLSurfaceView.Renderer', bpd.includes('GLSurfaceView.Renderer'));
t('bpd SceneRenderer tag', bpd.includes('SceneRenderer'));
t('bpd onDrawFrame', bpd.includes('onDrawFrame'));
t('bpd Matrix multiplyMM MVP chain', bpd.includes('Matrix.multiplyMM') && bpd.includes('Matrix.setRotateM'));
t('bpd setIdentityM init', bpd.includes('Matrix.setIdentityM'));
console.log('gl-canvas replay: ' + n + '/10 checks green');
