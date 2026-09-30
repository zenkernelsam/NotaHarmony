// Phase 1151 — cz8 ThreadLocal table accessor + sg5 registry
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const cz8 = R('cz8'), sg5 = R('sg5'), bh4 = R('bh4');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('cz8 extends ThreadLocal', cz8.includes('extends ThreadLocal'));
t('cz8{Function0 a factory, ix4 b binder}', cz8.includes('final Function0 a') && cz8.includes('final ix4 b'));
t('cz8 initialValue = a.invoke', cz8.includes('initialValue()') && cz8.includes('a.invoke()'));
t('cz8 get = super.get + b.invoke', cz8.includes('this.b.invoke(obj)'));
t('cz8.a() = bare super.get', cz8.includes('super.get()'));
t('sg5 has 12 cz8 holders', sg5.includes('cz8 c = new cz8') && sg5.includes('cz8 n'));
t('sg5.c = Id factory pg5+bh4(8)', sg5.includes('new cz8(pg5.I, new bh4(8))'));
t('sg5.d = SeqId factory og5+bh4(9)', sg5.includes('new cz8(og5.I, new bh4(9))'));
t('bh4 captures slot int', bh4.includes('class bh4 implements ix4') && bh4.includes('int I'));
t('sg5.b raw ThreadLocal scratch', sg5.includes('ThreadLocal b = new ThreadLocal()'));
console.log('cz8-holders replay: ' + n + '/10 checks green');
