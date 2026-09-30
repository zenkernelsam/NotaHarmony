// Phase 1267 — xd1/po3/f31/qu1/bt draw primitives
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const xd1 = R('xd1.java');
t('xd1 implements no3', xd1.includes('implements no3'));
t('xd1 wd1+b40 DrawParams/Canvas', xd1.includes('wd1 I') && xd1.includes('b40 J'));
t('xd1 bt K/L paint pool', xd1.includes('bt K') && xd1.includes('bt L'));
t('xd1 b() paint getColor', xd1.includes('paint.getColor'));
t('xd1 draw op B0', xd1.includes('void B0('));
const po3 = R('po3.java');
t('po3 abstract Brush', po3.includes('abstract class po3'));
const f31 = R('f31.java');
t('f31 a(alpha,size,bt)', f31.includes('a(float f, long j, bt btVar)'));
const qu1 = R('qu1.java');
t('qu1 ColorFilter wrap', qu1.includes('ColorFilter a'));
const bt = R('bt.java');
t('bt Paint holder', bt.includes('Paint a'));
t('xd1 draw ops I/U/b0', xd1.includes('void I(long') && xd1.includes('void U(f31') && xd1.includes('void b0(tr'));
console.log('draw-primitives replay: ' + n + '/10 checks green');
