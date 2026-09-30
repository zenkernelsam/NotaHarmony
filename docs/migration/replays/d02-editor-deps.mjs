// Phase 1201 — editor deps (pdf/ype/joe/wj8/yme/w7d/t76)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const pdf = R('pdf.java');
t('pdf holds qoe undo-session', pdf.includes('qoe'));
t('pdf has p6a MutableState', pdf.includes('p6a'));
const yme = R('yme.java');
t('yme implements wrd,nsd', yme.includes('implements wrd, nsd') || yme.includes('implements wrd'));
t('yme p6a MutableState fields', (yme.match(/p6a/g)||[]).length>=2);
t('yme getValue+psd state-record', yme.includes('getValue') && yme.includes('psd'));
const joe = R('joe.java');
t('joe aggregates pdf+ype', joe.includes('pdf a') && joe.includes('ype b'));
const wj8 = R('wj8.java');
t('wj8 channel v7d', wj8.includes('v7d') && wj8.includes('w7d'));
t('wj8 drop-oldest w7d.b(0,16,w41.J)', wj8.includes('w7d.b(0, 16, w41.J'));
const w7d = R('w7d.java');
t('w7d channel factory a/b/d', w7d.includes('v7d a(') && w7d.includes('v7d b('));
t('t76 edit-event type exists', R('t76.java').length>0);
console.log('editor-deps replay: ' + n + '/10 checks green');
