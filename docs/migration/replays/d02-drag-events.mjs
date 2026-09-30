// Phase 1243 — bq1/bq4 zo4/ap4 drag events
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const bq1 = R('bq1.java');
t('bq1 new zo4()', bq1.includes('new zo4()'));
t('bq1 j1(wj8,ap4)', bq1.includes('j1(wj8Var, new ap4(zo4Var))'));
t('bq1 "Drag & Drop"', bq1.includes('"Drag & Drop"'));
t('bq1 ns coroutine', bq1.includes('new ns(rd9Var'));
const bq4 = R('bq4.java');
t('bq4 extends n73 5 ifaces', bq4.includes('extends n73 implements mvc, o65, q52, sn9, vff'));
t('bq4 xp4 onFocusStateChange', bq4.includes('onFocusStateChange'));
t('bq4 h(xvc) requestFocus', bq4.includes('requestFocus'));
t('bq4 ap4 emit', bq4.includes('new ap4(zo4Var'));
t('bq4 j1 relay', bq4.includes('j1(wj8 wj8Var'));
t('bq1 invokes via wx4', bq1.includes('implements wx4'));
console.log('drag-events replay: ' + n + '/10 checks green');
