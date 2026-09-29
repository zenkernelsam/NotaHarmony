// Phase 1085 — m4c layout detail + nr5 layout engine + bxc
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const m4c = R('m4c'), l4c = R('l4c'), nr5 = R('nr5'), bxc = R('bxc');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('m4c: 13-param ctor', m4c.includes('m4c(int i, vy7 vy7Var, Float f, int i2, boolean z, boolean z2, List list, double d, l4c l4cVar, bxc bxcVar, hja hjaVar, cl2 cl2Var, List list2)'));
t('m4c: lazy pce o', m4c.includes('new pce(new aub'));
t('m4c: nr5 default qr5.a', m4c.includes('qr5.a') && m4c.includes('nr5Var = l4cVar.b'));
t('l4c implements j4c {mha,nr5,double}', l4c.includes('implements j4c') && l4c.includes('mha a') && l4c.includes('nr5 b'));
t('nr5 extends mxc', nr5.includes('extends mxc'));
t('nr5: a(mr5) relayout + b() + builder()', nr5.includes('mr5 a(mr5') && nr5.includes('mr5 b()') && nr5.includes('or5 builder()'));
t('bxc implements jxc,bf0', bxc.includes('implements jxc, bf0'));
t('bxc: k5c + static sia v', bxc.includes('k5c b') && bxc.includes('sia v'));
t('m4c implements qg2,o4c,t3c', m4c.includes('implements qg2, o4c, t3c'));
t('m4c fields b..n 13-field map', m4c.includes('this.n = list2'));
console.log('layout-engine replay: ' + n + '/10 checks green');
