// Phase 1148 — s06 payload-part types
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const pp7 = R('pp7'), dm2 = R('dm2'), d16 = R('d16'), u16 = R('u16');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('pp7{nr5} layout wrapper', pp7.includes('final nr5 a'));
t('pp7 EMPTY singleton b', pp7.includes('static final pp7 b'));
t('dm2 FlatBuffers table (cee,ka4)', dm2.includes('extends cee implements ka4'));
t('dm2.A()→float', dm2.includes('float A()'));
t('dm2.C(fqa)→fqa origin', dm2.includes('fqa C(fqa'));
t('dm2.a()→String name/value', dm2.includes('String a()'));
t('dm2.j()→mmf + k()/n()→hu1', dm2.includes('mmf j()') && dm2.includes('hu1 k()'));
t('d16{yc6×6} register-set', d16.includes('yc6 a') && d16.includes('yc6 f'));
t('u16 byte-enum + nz3 S', u16.includes('byte I') && u16.includes('nz3 S'));
t('s06 holds all parts', R('s06').includes('dm2 c') && R('s06').includes('d16 d') && R('s06').includes('pp7 f') && R('s06').includes('u16 k'));
console.log('s06-parts replay: ' + n + '/10 checks green');
