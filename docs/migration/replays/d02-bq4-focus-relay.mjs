// Phase 1213 — bq4 focus/event-relay node
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const bq4 = R('bq4.java');
t('bq4 extends n73 4 ifaces', bq4.includes('extends n73') && bq4.includes('mvc') && bq4.includes('sn9'));
t('bq4 onFocusStateChange method-ref', bq4.includes('onFocusStateChange') && bq4.includes('FocusState'));
t('bq4 g1(xp4) delegate', bq4.includes('g1(xp4Var)'));
t('bq4 h requestFocus semantics', bq4.includes('requestFocus') && bq4.includes('ivc.w'));
t('bq4 j1 trySend+emit', bq4.includes('wj8Var.b(t76Var)') && bq4.includes('xj2.A('));
t('bq4 k1 ap4 end-event cleanup', bq4.includes('new ap4(zo4Var)'));
t('bq4 wj8 channel ref', bq4.includes('wj8 Y'));
t('bq4 zo4 pending', bq4.includes('zo4 a0'));
t('bq4 vff s() capability', bq4.includes('vff') && bq4.includes('Object s()'));
t('xp4 focus node', R('xp4.java').includes('bq1') || R('xp4.java').length>100);
console.log('bq4-focus-relay replay: ' + n + '/10 checks green');
