// Phase 1192 — editor ViewModel (vle) + undo apply (dve inverse-op)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const vle = R('vle.java');
t('vle extends n73', vle.includes('extends n73'));
t('vle implements 11 ifaces', ['lo3','cma','mvc','o65','ara','jm6','q52','rd8','sn9','kv6','mp4'].every(i=>vle.includes(i)));
t('vle editor deps pdf/ype/joe/a46/nn6', ['pdf','ype','joe','a46','nn6'].every(f=>vle.includes(f)));
t('vle A(iqa,jqa) input handler', vle.includes('A(iqa') && vle.includes('jqa'));
t('vle undo uses nnf+ekd', vle.includes('nnf') && vle.includes('ekd'));
t('vle canUndo guard msg', vle.includes('canUndo') || vle.includes('nothing to undo'));
t('vle inverse dle.c apply', vle.includes('dle') && vle.includes('C1'));
const od8 = R('od8.java');
t('od8 implements j73 (ViewModel)', od8.includes('implements j73'));
t('n73 extends od8', R('n73.java').includes('extends od8'));
t('dve inverse-op record exists', readFileSync(D+'dve.java','utf8').length>0);
console.log('editor-vm replay: ' + n + '/10 checks green');
