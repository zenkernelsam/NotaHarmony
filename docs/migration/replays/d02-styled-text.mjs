// Phase 1224 — styled text (a00 AnnotatedString / zqe TextStyle)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const a00 = R('a00.java');
t('a00 implements CharSequence', a00.includes('implements CharSequence'));
t('a00 J text + I annotations', a00.includes('String J') && a00.includes('List I'));
t('a00 K/L span+paragraph lists', a00.includes('ArrayList K') && a00.includes('ArrayList L'));
t('a00 zz annotation split', a00.includes('zzVar') || a00.includes('zz '));
const zqe = R('zqe.java');
t('zqe gnd+e5a+ima fields', zqe.includes('gnd a') && zqe.includes('e5a b') && zqe.includes('ima c'));
t('zqe toString TextStyle color/fontSize/fontWeight', zqe.includes('TextStyle(color=') && zqe.includes('fontSize=') && zqe.includes('fontWeight='));
t('zqe b()->f31 brush', zqe.includes('f31 b()'));
t('zqe c()->long color', zqe.includes('long c()'));
t('zqe d/e merge+diff', zqe.includes('boolean d(zqe') && zqe.includes('zqe e(zqe'));
t('zz annotation type', R('zz.java').length>30);
console.log('styled-text replay: ' + n + '/10 checks green');
