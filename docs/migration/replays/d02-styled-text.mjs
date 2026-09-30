// Phase 1264 — a00/zqe AnnotatedString + TextStyle
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const a00 = R('a00.java');
t('a00 CharSequence+List I', a00.includes('implements CharSequence') && a00.includes('final List I'));
t('a00 String J text', a00.includes('final String J'));
t('a00 K/L span+para splits', a00.includes('ArrayList K') && a00.includes('ArrayList L'));
t('a00 zz annotation', a00.includes('zzVar'));
const zqe = R('zqe.java');
t('zqe gnd+e5a+ima styles', zqe.includes('gnd a') && zqe.includes('e5a b') && zqe.includes('ima c'));
t('zqe d default', zqe.includes('static final zqe d'));
t('zqe TextStyle toString', zqe.includes('TextStyle(color=') && zqe.includes('fontSize='));
t('zqe a()/f() copy', zqe.includes('static zqe a(zqe') && zqe.includes('static zqe f(zqe'));
t('zqe e() merge', zqe.includes('zqe e(zqe'));
t('zqe d(zqe) merge-guard', zqe.includes('boolean d(zqe'));
console.log('styled-text replay: ' + n + '/10 checks green');
