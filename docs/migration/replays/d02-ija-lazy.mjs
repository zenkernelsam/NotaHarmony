// Phase 1124 — ija lazy-materializing map semantics
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ija = R('ija');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ija abstract Map,ik6', ija.includes('abstract class ija implements Map, ik6'));
t('ija {gja I, LinkedHashMap J}', ija.includes('gja I') && ija.includes('LinkedHashMap J'));
t('ija ctor takes gja', ija.includes('ija(gja gjaVar)'));
t('get: J memo first', ija.includes('linkedHashMap.get(obj)') && ija.includes('return obj2'));
t('get: I.get → e() transform → J cache', ija.includes('this.I.get(obj)') && ija.includes('e(obj3)') && ija.includes('linkedHashMap.put'));
t('d: J.remove invalidate', ija.includes('this.J.remove(obj)'));
t('d: I.put write + c() hook', ija.includes('this.I.put(obj, obj2)') && ija.includes('c()'));
t('a(): flush J then f(I.build())', ija.includes('this.J.forEach') && ija.includes('f(this.I.build())'));
t('abstract b/e/f', ija.includes('abstract Object b(Object obj)') && ija.includes('abstract Object e(Object obj)') && ija.includes('abstract jja f(hja'));
t('c() empty hook', ija.includes('public void c()'));
console.log('ija-lazy replay: ' + n + '/10 checks green');
