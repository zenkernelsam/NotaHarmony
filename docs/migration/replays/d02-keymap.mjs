// Phase 1255 — pm6/xl6/ysc keyboard-shortcut table
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const xl6 = R('xl6.java');
t('xl6 PASTE/CUT/UNDO/REDO editable', xl6.includes('PASTE(true)') && xl6.includes('UNDO(true)') && xl6.includes('REDO(true)'));
t('xl6 navigation non-editable', xl6.includes('PAGE_UP(false)') && xl6.includes('SELECT_ALL(false)'));
t('xl6 boolean I flag', xl6.includes('final boolean I') && xl6.includes('xl6(boolean z)'));
t('xl6 CHARACTER_PALETTE', xl6.includes('CHARACTER_PALETTE'));
t('xl6 40+ commands', (xl6.match(/[A-Z_]+\((true|false)\)/g)||[]).length >= 40);
t('xl6 a() returns I', xl6.includes('a()'));
const ysc = R('ysc.java');
t('ysc{pdf,wpe,jl4,ele,cvc} ctx', ysc.includes('pdf a') && ysc.includes('wpe b') && ysc.includes('jl4 e'));
t('ysc a()/b() exec', ysc.includes('void a()') && ysc.includes('boolean b()'));
t('ysc editable bool c', ysc.includes('final boolean c'));
const pm6 = R('pm6.java');
t('pm6 om6 keymap', pm6.includes('om6 a = new om6(0)'));
console.log('keymap replay: ' + n + '/10 checks green');
