// Phase 1092 — sequence-tree node family qwc/rwc/xwc/ywc
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const qwc = R('qwc'), rwc = R('rwc'), xwc = R('xwc'), ywc = R('ywc'), g2c = R('g2c'), mxc = R('mxc');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('qwc implements swc (node nav)', qwc.includes('implements swc'));
t('qwc: {f8d,int} node', qwc.includes('qwc(f8d f8dVar, int i)'));
t('rwc implements swc (range nav)', rwc.includes('implements swc'));
t('rwc: d/e navigation methods', rwc.includes('hr5 d(hr5') && rwc.includes('rwc e(rwc'));
t('ywc: abstract base w/ Integer a', ywc.includes('abstract class ywc') && ywc.includes('Integer a'));
t('xwc extends ywc {qo5,g2c,long}', xwc.includes('extends ywc') && xwc.includes('qo5 b') && xwc.includes('g2c c') && xwc.includes('long d'));
t('g2c extends hvd wraps f2c', g2c.includes('extends hvd') && g2c.includes('f2c f2cVar'));
t('mxc: base iface', mxc.includes('interface mxc'));
t('xwc ctor (qo5,g2c,long)', xwc.includes('xwc(qo5 qo5Var, g2c g2cVar, long j)'));
t('xwc: a()/c() accessors', xwc.includes('a()') && xwc.includes('c()'));
console.log('seq-tree replay: ' + n + '/10 checks green');
