// Phase 1205 — vle keyboard/IME layer (Back-commit + keyboard controller)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const vle = R('vle.java');
t('vle.o(KeyEvent) exists', vle.includes('boolean o(KeyEvent'));
t('vle.o uses dli.a + jqe.d guard', vle.includes('dli.a(keyEvent)') && vle.includes('jqe.d'));
t('vle.o commits via qoe.a bme.I', vle.includes('qoe.a(qoeVar, a46Var, true, bme.I)'));
t('vle.o exits edit joeVar.y/z', vle.includes('joeVar.y(false)') && vle.includes('joeVar.z(mse.I)'));
t('vle.o1 keyboard controller', vle.includes('hld o1()') && vle.includes('No software keyboard controller'));
const dli = R('dli.java');
t('dli.a = KEYCODE_BACK(4)+UP(1)', dli.includes('getKeyCode() == 4') && dli.includes('== 1'));
t('dli.b ActionMode invalidateContentRect', dli.includes('invalidateContentRect'));
t('hld marker iface', R('hld.java').includes('public interface hld'));
const v52 = R('v52.java');
t('v52.r etd service token', v52.includes('etd r = new etd') || v52.includes('new etd('));
t('vle.p1 launches sle coroutine', vle.includes('new sle(this'));
console.log('vle-keyboard replay: ' + n + '/10 checks green');
