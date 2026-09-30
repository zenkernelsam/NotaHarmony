// Phase 1228 — vfc media texture / 360 stereo node
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const vfc = R('vfc.java');
t('vfc implements zxf,nc1', vfc.includes('implements zxf, nc1'));
t('vfc SurfaceTexture R', vfc.includes('SurfaceTexture R'));
t('vfc c(ts,dur,ot4,MediaFormat)', vfc.includes('void c(long j, long j2, ot4 ot4Var, MediaFormat'));
t('vfc ot4.C csd bytes', vfc.includes('ot4Var.C'));
t('vfc x6a box parse magic', vfc.includes('1886547818'));
t('vfc sphere mesh 15984/10656', vfc.includes('new float[15984]') && vfc.includes('new float[10656]'));
t('vfc 180/360 equirect radians', vfc.includes('Math.toRadians(180.0') && vfc.includes('Math.toRadians(360.0'));
t('vfc p0b stereo pair', vfc.includes('p0b') && vfc.includes('o0b'));
t('vfc OnFrameAvailable ufc', vfc.includes('OnFrameAvailableListener') && vfc.includes('ufc'));
t('vfc M duration->ts map', vfc.includes('this.M.b(j2, Long.valueOf(j))'));
console.log('vfc-media-texture replay: ' + n + '/10 checks green');
