// Phase 1257 — nnf/ekd/dve bounded undo stack
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const nnf = R('nnf.java');
t('nnf{cap,ekd undo,ekd redo}', nnf.includes('int a') && nnf.includes('ekd b') && nnf.includes('ekd c'));
t('nnf capacity positive guard', nnf.includes('Capacity must be a positive integer'));
t('nnf initial>capacity guard', nnf.includes('size greater than the given capacity'));
t('nnf addAll undo+redo', nnf.includes('addAll(list)') && nnf.includes('addAll(list2)'));
const ekd = R('ekd.java');
t('ekd Parcelable+nsd+List', ekd.includes('Parcelable, nsd, List'));
t('ekd RandomAccess+jk6', ekd.includes('RandomAccess, jk6'));
t('ekd isd snapshot delegate', ekd.includes('isd I'));
const dve = R('dve.java');
t('dve{pos,text x2,ts x3,oje}', dve.includes('final String b') && dve.includes('final String c') && dve.includes('final oje h'));
t('dve tab i companion', dve.includes('tab i'));
t('dve ije a() materialize', dve.includes('ije a()'));
console.log('undo-stack replay: ' + n + '/10 checks green');
