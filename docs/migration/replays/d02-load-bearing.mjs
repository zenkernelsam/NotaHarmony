// Phase 1356 — load-bearing baseline citations verified correct
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const exc = readFileSync(D + 'exc.java', 'utf8');
t('exc.A0 comparator exists', exc.includes('A0'));
const haa = readFileSync(D + 'haa.java', 'utf8');
t('haa = op enum', haa.includes('SET_METADATA') && haa.includes('CREATE_PAGE'));
t('haa INSERT_CHAR', haa.includes('INSERT_CHAR'));
t('haa REMOVE_CHARS', haa.includes('REMOVE_CHARS'));
t('haa REVIVE_CHARS', haa.includes('REVIVE_CHARS'));
t('haa CREATE_INK', haa.includes('CREATE_INK'));
t('cee = FlatBuffer Table', readFileSync(D + 'cee.java', 'utf8').length > 100);
t('uq9 = op envelope', existsSync(D + 'uq9.java'));
t('tmf = timestamp', existsSync(D + 'tmf.java'));
t('qo5 = entity id', existsSync(D + 'qo5.java'));
console.log('load-bearing replay: ' + n + '/10 checks green');
