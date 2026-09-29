// Phase 1088 — gja↔hja store builder↔snapshot cycle
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const gja = R('gja'), hja = R('hja'), ija = R('ija'), lk6 = R('lk6'), ik6 = R('ik6');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('gja extends Map,lk6 (builder)', gja.includes('extends Map, lk6'));
t('gja.build()→hja', gja.includes('hja build()'));
t('hja extends Map,ik6 (snapshot)', hja.includes('extends Map, ik6'));
t('hja.builder()→gja (cycle)', hja.includes('gja builder()'));
t('hja.put covariant→hja', hja.includes('hja put(Object obj, Object obj2)'));
t('ija.I = gja live store', ija.includes('gja'));
t('ija.f(hja) subview takes snapshot', ija.includes('f(hja hjaVar)'));
t('lk6 = mutable-collection marker', lk6.length > 0);
t('ik6 = immutable-collection marker', ik6.length > 0);
t('lk6/ik6 are collection-marker ifaces', lk6.includes('interface lk6') && ik6.includes('interface ik6'));
console.log('store-cycle replay: ' + n + '/10 checks green');
