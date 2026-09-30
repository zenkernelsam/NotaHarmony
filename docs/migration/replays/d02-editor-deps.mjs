// Phase 1269 — wc5/hi2/el8/in6/of1/n03 editor dep surface
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const wc5 = R('wc5.java'), hi2 = R('hi2.java');
t('wc5 iface', wc5.includes('interface wc5'));
t('hi2 iface', hi2.includes('interface hi2'));
const el8 = R('el8.java');
t('el8 s7d+ol4 flow emitter', el8.includes('extends s7d, ol4'));
t('el8 emit+f+a', el8.includes('emit(Object') && el8.includes('boolean f(') && el8.includes('void a('));
const in6 = R('in6.java');
t('in6 a(rle) listener', in6.includes('a(rle'));
const of1 = R('of1.java');
t('of1 6-float spec', of1.includes('float a') && of1.includes('float f'));
t('of1 a→wrd modifier factory', of1.includes('wrd a(boolean') && of1.includes('wj8'));
t('of1 uz4 Composer+remember', of1.includes('uz4') && of1.includes('fsi.T'));
const n03 = R('n03.java');
t('n03 combine collector', n03.includes('implements ol4') && n03.includes('Object emit('));
const joe = R('joe.java');
t('joe wc5 dep', joe.includes('wc5'));
console.log('editor-deps replay: ' + n + '/10 checks green');
