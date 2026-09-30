// Phase 1149 — hp5/cie block specs + real schema-name leak
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const hp5 = R('hp5'), cie = R('cie');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('hp5 implements xy0,be5,bf0,ce5,oy0', hp5.includes('implements xy0, be5, bf0, ce5, oy0'));
t('hp5 m4c member-collection', hp5.includes('final m4c d'));
t('hp5 cropRect prop (Rect schema)', hp5.includes('"cropRect"') && hp5.includes('flatbuffers/Rect'));
t('hp5 imageFlippedVertically', hp5.includes('"imageFlippedVertically"'));
t('hp5 imageFlippedHorizontally', hp5.includes('"imageFlippedHorizontally"'));
t('hp5(ry0,yc6,m4c,yc6,yc6) ctor', hp5.includes('hp5(ry0 ry0Var, yc6 yc6Var, m4c m4cVar'));
t('cie implements xy0,xhe,be5,bf0,ce5', cie.includes('implements xy0, xhe, be5, bf0, ce5'));
t('cie paper prop (Paper schema)', cie.includes('"paper"') && cie.includes('flatbuffers/Paper'));
t('cie resizesWidthToFitText', cie.includes('"resizesWidthToFitText"'));
t('cie m4c member + m4c.q assign', cie.includes('final m4c c') && cie.includes('this.g = m4cVar.q'));
console.log('block-specs replay: ' + n + '/10 checks green');
