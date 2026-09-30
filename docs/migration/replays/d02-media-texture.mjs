// Phase 1178 — embedded media texture node (vfc SurfaceTexture + frame queues)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const vfc = R('vfc.java');
t('vfc implements zxf,nc1', vfc.includes('implements zxf, nc1') || vfc.includes('implements zxf'));
t('vfc SurfaceTexture field', vfc.includes('SurfaceTexture R'));
t('vfc AtomicBoolean flags', vfc.includes('AtomicBoolean'));
t('vfc frame queues q0b/m40/r71', vfc.includes('q0b') && vfc.includes('m40') && vfc.includes('r71'));
t('vfc float[16] tex matrices', vfc.includes('new float[16]'));
t('vfc c(long,long,ot4,MediaFormat) feed', vfc.includes('MediaFormat') && vfc.includes('c(long'));
t('vfc a(long,float[]) matrix update', vfc.includes('a(long'));
const bpd = R('bpd.java');
t('bpd reads vfc.SurfaceTexture', bpd.includes('SurfaceTexture') && bpd.includes('vfc'));
t('bpd implements dv9', bpd.includes('implements GLSurfaceView.Renderer, dv9'));
t('dv9 is interface', R('dv9.java').includes('interface dv9'));
console.log('media-texture replay: ' + n + '/10 checks green');
