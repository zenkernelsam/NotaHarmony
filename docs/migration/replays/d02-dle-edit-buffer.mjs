// Phase 1222 — dle TextEditBuffer method surface
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const dle = R('dle.java');
t('dle implements Appendable', dle.includes('implements Appendable'));
t('dle b setComposingRegion(3 int)', dle.includes('void b(int i, int i2, int i3)'));
t('dle c replace(i,i2,cs)', dle.includes('void c(int i, int i2, CharSequence'));
t('dle e setComposition(jqe)', dle.includes('void e(jqe'));
t('dle f setSelection(long)', dle.includes('void f(long'));
t('dle a()->rnh finishEditing', dle.includes('rnh a()'));
t('dle c clamps via rh8.v x4', (dle.match(/rh8\.v\(/g)||[]).length>=4);
t('dle d markup insert', dle.includes('void d(int i, int i2, List'));
t('dle toString K buffer', dle.includes('this.K.toString()'));
t('rnh commit result type', R('rnh.java').length>50);
console.log('dle-edit-buffer replay: ' + n + '/10 checks green');
