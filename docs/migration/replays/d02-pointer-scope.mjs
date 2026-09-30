// Phase 1248 — u8e pointerInput node
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const u8e = R('u8e.java');
t('u8e extends od8 bra+r93+ara', u8e.includes('extends od8 implements bra, r93, ara'));
t('u8e PointerInputEventHandler Y', u8e.includes('PointerInputEventHandler Y'));
t('u8e PointerInputResetException import', u8e.includes('PointerInputResetException'));
t('u8e iqa a0 = q8e.a', u8e.includes('iqa a0 = q8e.a'));
t('u8e tqd Z handler job', u8e.includes('tqd Z'));
t('u8e ql8 b0/c0/d0 history', u8e.includes('ql8 b0') && u8e.includes('ql8 d0'));
t('u8e e0 prev + f0 downTime', u8e.includes('iqa e0') && u8e.includes('long f0'));
const bra = R('bra.java');
t('bra extends r93 Density', bra.includes('interface bra extends r93'));
const ara = R('ara.java');
t('ara extends j73 node', ara.includes('interface ara extends j73'));
t('u8e ctor(handler)', u8e.includes('u8e(Object obj, Object obj2, PointerInputEventHandler'));
console.log('pointer-scope replay: ' + n + '/10 checks green');
