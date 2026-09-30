// Phase 1231 — bpd SceneRenderer 360 head-tracking render loop
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const bpd = R('bpd.java');
t('bpd implements Renderer,dv9', bpd.includes('implements GLSurfaceView.Renderer, dv9'));
t('bpd a() stores L+roll M', bpd.includes('arraycopy(fArr, 0, fArr2') && bpd.includes('this.P = f2'));
t('bpd MVP chain K=JxQ', bpd.includes('multiplyMM(this.Q, 0, this.M, 0, this.R, 0)') && bpd.includes('multiplyMM(this.K, 0, this.J, 0, this.Q, 0)'));
t('bpd updateTexImage CAS', bpd.includes('compareAndSet(true, false)') && bpd.includes('updateTexImage()'));
t('bpd getTimestamp->vfc.M', bpd.includes('getTimestamp()') && bpd.includes('vfcVar.M'));
t('bpd per-frame rotation m40', bpd.includes('Matrix.length(f, f2, f3)') && bpd.includes('setRotateM'));
t('bpd p0b stereo metadata', bpd.includes('p0bVar') && bpd.includes('q0b.b(p0bVar)'));
t('bpd r71 FloatBuffer mesh', bpd.includes('FloatBuffer') && bpd.includes('ByteOrder.nativeOrder()'));
t('bpd vfc.P=K x O', bpd.includes('multiplyMM(vfcVar.P, 0, fArr2, 0, vfcVar.O, 0)'));
t('bpd perspectiveM fov', bpd.includes('Matrix.perspectiveM') && bpd.includes('100.0f'));
console.log('bpd-360-render replay: ' + n + '/10 checks green');
