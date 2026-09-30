// Phase 1217 — text value layer (ele/jqe/k1a/dle)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ele = R('ele.java');
t('ele implements CharSequence', ele.includes('implements CharSequence'));
t('ele delegates charAt/length/subSequence', ele.includes('char charAt') && ele.includes('int length()') && ele.includes('CharSequence subSequence'));
t('ele K text + L selection + M/N ranges', ele.includes('CharSequence K') && ele.includes('long L') && ele.includes('jqe M') && ele.includes('k1a N'));
t('ele clamps via rh8.A', ele.includes('rh8.A(charSequence.length()'));
const jqe = R('jqe.java');
t('jqe packed long a', jqe.includes('long a'));
t('jqe collapsed check d', jqe.includes('(j >> 32)) == ((int) (j & 4294967295L'));
t('jqe empty b = rh8.i(0,0)', jqe.includes('rh8.i(0, 0)'));
const dle = R('dle.java');
t('dle implements Appendable', dle.includes('implements Appendable'));
t('dle append x3', (dle.match(/Appendable append\(/g)||[]).length>=3);
t('k1a Serializable I+J', R('k1a.java').includes('implements Serializable') && R('k1a.java').includes('Object I') && R('k1a.java').includes('Object J'));
console.log('text-values replay: ' + n + '/10 checks green');
