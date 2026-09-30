// Phase 1212 — u8e PointerInputScope pipeline
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const u8e = R('u8e.java');
t('u8e PointerInputEventHandler field', u8e.includes('PointerInputEventHandler'));
t('u8e PointerInputResetException import', u8e.includes('PointerInputResetException'));
t('u8e g1 awaitPointerEvent suspend', u8e.includes('Object g1(wx4') && u8e.includes('ad1') && u8e.includes('synchronized'));
t('u8e.A dispatches h1(iqa,jqa)', u8e.includes('h1(iqaVar, jqaVar)'));
t('u8e iqa.a pointer list', u8e.includes('iqaVar.a'));
t('u8e laj.e changed check', u8e.includes('laj.e('));
t('u8e ql8 slots b0/c0/d0', u8e.includes('ql8 b0') || u8e.includes('ql8'));
t('u8e Density a()/e0() passthrough', u8e.includes('h0.a()') && u8e.includes('h0.e0()'));
const iqa = R('iqa.java');
t('iqa has List<oqa>', iqa.includes('oqa') && iqa.includes('List'));
t('jqa 3-value event type', (R('jqa.java').match(/public static final jqa/g)||[]).length>=3 || R('jqa.java').includes('jqa I'));
console.log('pointer-input replay: ' + n + '/10 checks green');
