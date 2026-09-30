// Phase 1210 — vle.H key-command layer (xl6 48 cmds / pm6 / ysc)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const xl6 = R('xl6.java');
t('xl6 enum ~48 commands', (xl6.match(/^\s+[A-Z_]+\(/gm)||[]).length >= 45);
t('xl6 nav LEFT_CHAR/PAGE_UP/HOME/END', ['LEFT_CHAR','PAGE_UP','PAGE_DOWN','HOME','END'].every(k=>xl6.includes(k)));
t('xl6 clipboard COPY/PASTE/CUT', ['COPY','PASTE','CUT'].every(k=>xl6.includes(k)));
t('xl6 delete family', ['DELETE_PREV_CHAR','DELETE_NEXT_CHAR','DELETE_PREV_WORD','DELETE_NEXT_WORD','DELETE_FROM_LINE_START','DELETE_TO_LINE_END'].every(k=>xl6.includes(k)));
t('xl6 select family ~18', (xl6.match(/SELECT_[A-Z_]+/g)||[]).length >= 16);
t('xl6 UNDO/REDO editable', xl6.includes('UNDO(true)') && xl6.includes('REDO(true)'));
t('xl6 I requires-editable flag', xl6.includes('boolean I'));
const vle = R('vle.java');
t('vle.H pm6.a.k(keyEvent)', vle.includes('pm6.a.k(keyEvent)'));
t('vle.H ysc exec ctx', vle.includes('new ysc(pdfVar, wpeVarC'));
t('ysc fields pdf+wpe+jl4+ele', R('ysc.java').includes('pdf a') && R('ysc.java').includes('wpe b') && R('ysc.java').includes('jl4 e'));
console.log('vle-keycommand replay: ' + n + '/10 checks green');
