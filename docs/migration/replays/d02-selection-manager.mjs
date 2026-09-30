// Phase 1262 — joe/mse/r95/zne selection manager
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const joe = R('joe.java');
t('joe{pdf,ype,r93}', joe.includes('pdf a') && joe.includes('ype b') && joe.includes('r93 c'));
t('joe k6f+hi2+yla+tr1', joe.includes('k6f e') && joe.includes('hi2 f') && joe.includes('yla g') && joe.includes('tr1 h'));
t('joe wc5 clipboard', joe.includes('wc5 j'));
const mse = R('mse.java');
t('mse HandleState None/Cursor/Selection', mse.includes('"None"') && mse.includes('"Cursor"') && mse.includes('"Selection"'));
const r95 = R('r95.java');
t('r95 Handle Cursor/SelStart/SelEnd', r95.includes('"Cursor"') && r95.includes('"SelectionStart"') && r95.includes('"SelectionEnd"'));
const zne = R('zne.java');
t('zne TouchMode enum', zne.includes('"None"') && zne.includes('zne J'));
const tr1 = R('tr1.java');
t('tr1 HapticFeedback iface', tr1.includes('interface tr1'));
t('joe Function0 l,m callbacks', joe.includes('Function0 l') && joe.includes('Function0 m'));
t('mse I,J,K 3 values', mse.includes('mse I') && mse.includes('mse K'));
t('r95 I,J,K 3 values', r95.includes('r95 I') && r95.includes('r95 K'));
console.log('selection-manager replay: ' + n + '/10 checks green');
