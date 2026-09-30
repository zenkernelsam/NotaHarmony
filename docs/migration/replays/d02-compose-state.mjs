// Phase 1193 — Compose snapshot-state layer (p6a MutableState + osd/yjd/zjd/tjd)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const p6a = R('p6a.java');
t('p6a extends osd implements yjd', p6a.includes('extends osd') && p6a.includes('yjd'));
t('p6a MutableState toString', p6a.includes('MutableState(value='));
t('p6a SnapshotMutationPolicy mention', p6a.includes('SnapshotMutationPolicy'));
t('p6a Parcelable', p6a.includes('Parcelable'));
t('p6a uses zjd/tjd snapshot internals', p6a.includes('zjd') && p6a.includes('tjd'));
t('osd snapshot-state base exists', R('osd.java').length>0);
t('yjd mutation-policy iface', R('yjd.java').length>0);
t('od8/j73 ViewModel iface chain', R('od8.java').includes('implements j73'));
const cvc = R('cvc.java');
t('cvc {u4g a,u4g b} text range', cvc.includes('u4g a') && cvc.includes('u4g b'));
t('dve undo record int+longs', R('dve.java').includes('int a') && R('dve.java').includes('long d'));
console.log('compose-state replay: ' + n + '/10 checks green');
