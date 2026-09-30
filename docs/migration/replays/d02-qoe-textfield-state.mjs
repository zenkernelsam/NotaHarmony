// Phase 1216 — qoe TextFieldState + wx5 undo session
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const qoe = R('qoe.java');
t('qoe wx5 delegate', qoe.includes('wx5 a'));
t('qoe dle TextEditBuffer', qoe.includes('dle b'));
t('qoe p6a x3 MutableState', (qoe.match(/p6a [cde]/g)||[]).length>=3);
t('qoe spd processor', qoe.includes('spd f'));
t('qoe ql8 pending ops', qoe.includes('ql8 g'));
t('qoe a46.i sink', qoe.includes('a46Var.i(dleVar3)'));
t('qoe ele new-state construct', qoe.includes('new ele('));
const wx5 = R('wx5.java');
t('wx5 nnf undo stack', wx5.includes('nnf nnfVar'));
t('wx5 ekd undo+redo', wx5.includes('ekdVar.b') || (wx5.includes('nnfVar.b') && wx5.includes('nnfVar.c')));
t('wx5 capacity evict + dve push', wx5.includes('nnfVar.a - 1') && wx5.includes('dveVar'));
console.log('qoe-textfield-state replay: ' + n + '/10 checks green');
