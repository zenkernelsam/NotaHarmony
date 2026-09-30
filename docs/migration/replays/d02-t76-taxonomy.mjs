// Phase 1240 — t76 event taxonomy (start<->end pairs)
import { readFileSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const sj5 = R('sj5.java'), ap4 = R('ap4.java'), ml3 = R('ml3.java');
t('sj5{rj5} end pair', sj5.includes('final rj5 a'));
t('ap4{zo4} end pair', ap4.includes('final zo4 a'));
t('ml3{ll3} end pair', ml3.includes('final ll3 a'));
const nn3 = R('nn3.java'), ln3 = R('ln3.java');
t('nn3{mn3} end-A', nn3.includes('final mn3 a'));
t('ln3{mn3} end-B (mn3 1:2)', ln3.includes('final mn3 a'));
const gwa = R('gwa.java'), ewa = R('ewa.java');
t('gwa{fwa} end-A', gwa.includes('final fwa a'));
t('ewa{fwa} end-B', ewa.includes('final fwa a'));
const fwa = R('fwa.java');
t('fwa{long} timed start', fwa.includes('final long a'));
const mn3 = R('mn3.java'), rj5 = R('rj5.java');
t('mn3/rj5 singleton starts', mn3.includes('implements t76') && rj5.includes('implements t76'));
const files = readdirSync(D);
t('mn3 emitted by gn3', files.includes('gn3.java') && R('gn3.java').includes('new mn3('));
console.log('t76-taxonomy replay: ' + n + '/10 checks green');
