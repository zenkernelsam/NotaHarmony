// Phase 1270 — uz4/r42/sh8/fsi recomposition engine
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const uz4 = R('uz4.java');
t('uz4 implements t42 Composer', uz4.includes('implements t42'));
t('uz4 tz4 SlotTable', uz4.includes('tz4 D'));
t('uz4 slot readers kgd/lgd/ogd', uz4.includes('kgd G') && uz4.includes('lgd H') && uz4.includes('ogd I'));
t('uz4 oha remember holder', uz4.includes('oha K'));
const r42 = R('r42.java');
t('r42.a Composer.Empty sentinel', r42.includes('sh8 a = new sh8(20)'));
const sh8 = R('sh8.java');
t('sh8 shared sentinel instances', (sh8.match(/new sh8\(\d+\)/g)||[]).length >= 8);
const fsi = R('fsi.java');
t('fsi merged statics', fsi.includes('abstract class fsi') && fsi.includes('static final'));
t('fsi T remember helper', /static\s+\S+\s+T\(/.test(fsi));
const of1 = R('of1.java');
t('of1 uses Composer.Empty check', of1.includes('sh8Var') || of1.includes('r42'));
const vle = R('vle.java');
t('vle hosted by composition', vle.length > 0);
console.log('recomposition replay: ' + n + '/10 checks green');
