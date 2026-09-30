// Phase 1187 — a76 int-rect + r93 Density iface (viewport geometry/units)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const a76 = R('a76.java');
t('a76 4-int rect', a76.includes('int a') && a76.includes('int d'));
t('a76 c() height d-b', a76.includes('this.d - this.b'));
t('a76 f() width c-a', a76.includes('this.c - this.a'));
t('a76 long-pack <<32', a76.includes('<< 32') && a76.includes('4294967295L'));
t('a76 e()/d() packed accessors', a76.includes('long e()') && a76.includes('long d()'));
const r93 = R('r93.java');
t('r93 interface (Density)', r93.includes('interface r93'));
t('r93 B(long)→float', r93.includes('float B(long'));
t('r93 C0/j0 conversions', r93.includes('C0') && r93.includes('j0'));
t('r93 cl3 unpack + floatToRawIntBits', r93.includes('cl3') && r93.includes('floatToRawIntBits'));
t('r93 ds4.a consts', r93.includes('ds4.a'));
console.log('rect-density replay: ' + n + '/10 checks green');
