// Phase 1102 — via builder / wia store / uia snapshot / tia / xia / lia
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const via = R('via'), wia = R('wia'), uia = R('uia'), tia = R('tia'),
      xia = R('xia'), lia = R('lia');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('via = abstract w/ {wia J, fm8 L, LinkedHashMap K}', via.includes('LinkedHashMap') && via.includes('fm8.a()') && via.includes('abstract class via'));
t('via.a() folds pending → wia.b', via.includes('wiaVar.b(') && via.includes('wiaVar.a()'));
t('via.b abstract value-transform', via.includes('public abstract Object b(Object obj)'));
t('via mutex + snapshot', via.includes('fm8') && via.includes('public vz a()'));
t('wia = {sia a, igf c} store', wia.includes('sia a') && wia.includes('igf c'));
t('wia.b(long,obj) packed-key write', wia.includes('b(long j, Object obj)'));
t('wia.a()→sia index snapshot', wia.includes('sia a()'));
t('uia extends vz Map,ik6', uia.includes('extends vz implements Map, ik6'));
t('tia extends via', tia.includes('extends via'));
t('xia cursor {wia,long,int} + lia view', xia.includes('extends fr5') && xia.includes('wia L') && lia.includes('extends w4 implements Collection, jk6'));
console.log('mapbuilder replay: ' + n + '/10 checks green');
