// Phase 1218 — joe TextFieldSelectionManager (named enums)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const mse = R('mse.java');
t('mse HandleState None/Cursor/Selection', mse.includes('"None"') && mse.includes('"Cursor"') && mse.includes('"Selection"'));
const r95 = R('r95.java');
t('r95 Cursor/SelectionStart/End', r95.includes('"Cursor"') && r95.includes('"SelectionStart"') && r95.includes('End'));
const zne = R('zne.java');
t('zne None/Touch', zne.includes('"None"') && zne.includes('"Touch"'));
const joe = R('joe.java');
t('joe zn9 Offset.Unspecified handles', (joe.match(/new zn9\(9205357640488583168/g)||[]).length>=2);
t('joe mse mode state', joe.includes('mse.I'));
t('joe zne toolbar state', joe.includes('zne.I'));
t('joe.A IME watch eje/tqd', joe.includes('eje') && joe.includes('tqd'));
t('joe.c cursor rect', joe.includes('cmb c(wpe'));
t('joe.D word resolve gqc/xc5', joe.includes('gqc') && joe.includes('xc5'));
t('joe k6f IME holder', joe.includes('k6f e'));
console.log('joe-selection-manager replay: ' + n + '/10 checks green');
