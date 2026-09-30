// Phase 1258 — o7a/dle/ele/jqe text buffer internals
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const o7a = R('o7a.java');
t('o7a CharSequence gap-buffer', o7a.includes('implements CharSequence') && o7a.includes('pz4 J'));
t('o7a char[] copy replace', o7a.includes('new char[') && o7a.includes('a(int i, int i2, CharSequence'));
const dle = R('dle.java');
t('dle implements Appendable', dle.includes('implements Appendable'));
t('dle{ele,o7a,jqe,rnh}', dle.includes('ele I') && dle.includes('o7a K') && dle.includes('jqe N'));
t('dle g() materializes ele', dle.includes('static ele g(dle') && dle.includes('K.toString()'));
const ele = R('ele.java');
t('ele CharSequence+lists', ele.includes('implements CharSequence') && ele.includes('final List I'));
t('ele rh8.A clamp sel', ele.includes('rh8.A(charSequence.length()'));
t('ele jqe M + k1a N', ele.includes('jqe M') && ele.includes('k1a N'));
const jqe = R('jqe.java');
t('jqe packed long TextRange', jqe.includes('final long a') && jqe.includes('rh8.i(0, 0)'));
t('jqe d() collapsed', jqe.includes('boolean d(long'));
console.log('text-buffer replay: ' + n + '/10 checks green');
