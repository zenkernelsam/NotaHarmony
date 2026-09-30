// Phase 1144 — v69.y affected-id batch collect
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const v69 = R('v69');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('v69.y(coll,set,u69)→LinkedHashSet', v69.includes('LinkedHashSet y(Collection collection, Set set, u69 u69Var)'));
t('v69.x(coll,ff2)→Serializable', v69.includes('java.io.Serializable x(java.util.Collection'));
t('x decompiled-too-complex (parallel collect)', v69.includes('Method not decompiled'));
t('y: bl2 tombstone entries', v69.includes('new bl2(uq9Var.l(), new tz9'));
t('y: r09 page entity ref', v69.includes('new r09(((tz9)'));
t('y: t09 id-list ref', v69.includes('new t09(null, listF)'));
t('y: lia op buffer', v69.includes('liaVar.add(uq9Var)'));
t('y: LinkedHashMap work map', v69.includes('LinkedHashMap linkedHashMap = new LinkedHashMap()'));
t('y: qw3.I empty-set default', v69.includes('qw3.I'));
t('u69 classifier type exists', R('u69').length > 30);
console.log('v69-collect replay: ' + n + '/10 checks green');
