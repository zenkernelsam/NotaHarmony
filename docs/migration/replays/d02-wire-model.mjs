// Phase 1152 — core/model note+page wire-models
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/core/model/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const a = R('a'), b = R('b'), c = R('c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('model.a = note bundle class', a.includes('final class a'));
t('a.k = root-page sentinel nti.g(rh8.b(0,-1),0)', a.includes('nti.g(rh8.b(0, -1), 0)'));
t('a: bs1 bundle head', a.includes('final bs1 a'));
t('a: fqa origin + String name', a.includes('final fqa c') && a.includes('final String d'));
t('a: entity maps ×4', a.includes('LinkedHashMap f') && a.includes('LinkedHashMap i'));
t('a(fqa,String,int) ctor + l96.M bs1', a.includes('a(fqa fqaVar, String str, int i)') && a.includes('l96.M((short) 0)'));
t('model.c = page wire-model', c.includes('final class c'));
t('c: ArrayList ops + cxc pageId', c.includes('final ArrayList a') && c.includes('final cxc c'));
t('c: sub-maps e..g + h', c.includes('LinkedHashMap e') && c.includes('LinkedHashMap g') && c.includes('ArrayList h'));
t('model.b abstract materializer a(a79)→th7', b.includes('abstract class b') && b.includes('th7 a(a79'));
console.log('wire-model replay: ' + n + '/10 checks green');
