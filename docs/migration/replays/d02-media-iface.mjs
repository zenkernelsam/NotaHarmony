// Phase 1179 — media frame-feed ifaces (zxf/nc1) + bpd renderer lifecycle
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const zxf = R('zxf.java');
t('zxf interface', zxf.includes('interface zxf'));
t('zxf c(long,long,ot4,MediaFormat)', zxf.includes('c(long') && zxf.includes('MediaFormat'));
const nc1 = R('nc1.java');
t('nc1 interface', nc1.includes('interface nc1'));
t('nc1 a(long,float[])+b()', nc1.includes('a(long') && nc1.includes('float[]') && nc1.includes('void b()'));
t('vfc implements zxf+nc1', R('vfc.java').includes('zxf') && R('vfc.java').includes('nc1'));
const bpd = R('bpd.java');
t('bpd onSurfaceCreated', bpd.includes('onSurfaceCreated'));
t('bpd onSurfaceChanged', bpd.includes('onSurfaceChanged'));
t('bpd onDrawFrame', bpd.includes('onDrawFrame'));
t('bpd EGLConfig param', bpd.includes('EGLConfig'));
t('bpd GL10 param', bpd.includes('GL10'));
console.log('media-iface replay: ' + n + '/10 checks green');
