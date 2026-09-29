// Phase 1084 — cie/hp5 member-collection entities + m4c spec
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const cie = R('cie'), hp5 = R('hp5'), m4c = R('m4c'), dp5 = R('dp5');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('cie implements xy0,xhe,be5,bf0,ce5', cie.includes('implements xy0, xhe, be5, bf0, ce5'));
t('cie: ry0 spec + m4c member + vy7', cie.includes('ry0 b') && cie.includes('m4c c') && cie.includes('vy7 f'));
t('cie props: paper,resizesWidthToFitText', cie.includes('"paper"') && cie.includes('"resizesWidthToFitText"'));
t('hp5 implements xy0,be5,bf0,ce5,oy0', hp5.includes('implements xy0, be5, bf0, ce5, oy0'));
t('hp5: ry0 + m4c d + dp5 g + String i', hp5.includes('ry0 b') && hp5.includes('m4c d') && hp5.includes('dp5 g') && hp5.includes('String i'));
t('m4c implements qg2,o4c,t3c', m4c.includes('implements qg2, o4c, t3c'));
t('m4c: rich ctor (vy7,Float,lists,l4c,bxc,hja,cl2)', m4c.includes('vy7 vy7Var') && m4c.includes('l4c l4cVar') && m4c.includes('bxc bxcVar') && m4c.includes('hja hjaVar') && m4c.includes('cl2 cl2Var'));
t('m4c.D = copy-with', m4c.includes('m4c D(m4c m4cVar'));
t('dp5 extends cee + ka4 + ddg.i', dp5.includes('extends cee implements ka4') && dp5.includes('ddg.i'));
t('cie/hp5: bf0 = spec marker', cie.includes('bf0') && hp5.includes('bf0'));
console.log('member-collection replay: ' + n + '/10 checks green');
