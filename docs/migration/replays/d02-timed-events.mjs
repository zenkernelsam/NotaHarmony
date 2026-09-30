// Phase 1239 — hwa/fwa/gwa/ewa timed-gesture events
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const hwa = R('hwa.java');
t('hwa extends t76', hwa.includes('interface hwa extends t76'));
const fwa = R('fwa.java');
t('fwa implements hwa', fwa.includes('implements hwa'));
t('fwa long a timestamp', fwa.includes('final long a'));
const gwa = R('gwa.java');
t('gwa implements hwa', gwa.includes('implements hwa'));
t('gwa wraps fwa a', gwa.includes('final fwa a'));
t('gwa ctor(fwa)', gwa.includes('gwa(fwa fwaVar)'));
const ewa = R('ewa.java');
t('ewa implements hwa', ewa.includes('implements hwa'));
t('ewa wraps fwa a', ewa.includes('final fwa a'));
t('ewa ctor(fwa)', ewa.includes('ewa(fwa fwaVar)'));
t('gwa,ewa distinct ends', gwa.includes('gwa(fwa') && ewa.includes('ewa(fwa'));
console.log('timed-events replay: ' + n + '/10 checks green');
