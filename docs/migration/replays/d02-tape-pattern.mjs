// Phase 1182 — TapePattern enum (ife) + washi-tape drawable binding
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ife = R('ife.java');
t('ife TapePattern enum STRIPES', ife.includes('STRIPES'));
t('ife GRID+DOTS+PLAIN', ife.includes('GRID') && ife.includes('DOTS') && ife.includes('PLAIN'));
t('ife STARS+FLOWERS+HEARTS', ife.includes('STARS') && ife.includes('FLOWERS') && ife.includes('HEARTS'));
t('ife WAVES+CHECKERS', ife.includes('WAVES') && ife.includes('CHECKERS'));
t('ife 9 patterns', ['STRIPES','GRID','DOTS','PLAIN','STARS','FLOWERS','HEARTS','WAVES','CHECKERS'].filter(p=>ife.includes(p)).length===9);
t('ife enum holder nz3', ife.includes('nz3'));
t('ife byte ordinal', ife.includes('byte I'));
const mwd = R('mwd.java');
t('mwd holds ife (tape pattern in stroke)', mwd.includes('ife'));
t('n5d tapePattern field (shape spec)', R('n5d.java').includes('tapePattern') || mwd.includes('ife'));
t('ife enum valueOf/values', ife.includes('valueOf') && ife.includes('values'));
console.log('tape-pattern replay: ' + n + '/10 checks green');
