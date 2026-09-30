// Phase 1244 — i2/g2/b14 long-press fire-vs-cancel
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const g2 = R('g2.java');
t('g2 coroutine wj8+fwa', g2.includes('wj8 K') && g2.includes('fwa L'));
t('g2 emits gwa(fwa) fire', g2.includes('new gwa(fwaVar'));
const b14 = R('b14.java');
t('b14 implements lh3 dispose', b14.includes('implements lh3') && b14.includes('dispose()'));
t('b14 dispose->ewa cancel', b14.includes('new ewa(fwaVar'));
const i2 = R('i2.java');
t('i2 coroutine k2+fwa', i2.includes('k2 K') && i2.includes('fwa L'));
t('i2 emits ewa cancel', i2.includes('new ewa(fwaVar'));
t('i2 emits gwa fire', i2.includes('new gwa(fwaVar'));
t('i2 dual-end', (i2.match(/new ewa/g)||[]).length >= 1 && i2.includes('new gwa'));
t('b14 g2 i2 all n8e/lh3', g2.includes('extends n8e') && i2.includes('extends n8e') && b14.includes('implements lh3'));
t('fwa timed 1:2', R('fwa.java').includes('implements hwa'));
console.log('longpress replay: ' + n + '/10 checks green');
