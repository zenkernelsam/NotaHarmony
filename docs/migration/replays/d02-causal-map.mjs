// Phase 1087 — ija read-only lazy-materialize causal map
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ija = R('ija'), kja = R('kja'), pja = R('pja');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ija implements Map,ik6', ija.includes('implements Map, ik6'));
t('ija: J LinkedHashMap cache', ija.includes('public final LinkedHashMap J'));
t('ija: I = gja backing store', ija.includes('gja I') || ija.includes('.I.get(obj)'));
t('get: cache-then-materialize', ija.includes('linkedHashMap.get(obj)') && ija.includes('objE = e(obj3)'));
t('get: e() materialize + J.put cache', ija.includes('linkedHashMap.put(obj, objE)'));
t('ija: read-only (put throws)', ija.includes('UnsupportedOperationException("Operation is not supported for read-only collection")'));
t('ija: merge/putAll/put all throw', (ija.match(/UnsupportedOperationException/g) || []).length >= 4);
t('ija.f(hja) abstract subview', ija.includes('jja f(hja hjaVar)'));
t('kja/pja extend ija', kja.includes('extends ija') && pja.includes('extends ija'));
t('ija: keySet delegates to I', ija.includes('this.I.keySet()'));
console.log('causal-map replay: ' + n + '/10 checks green');
