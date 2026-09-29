// Phase 1019 — ssf auth/session service
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const ssf = readFileSync(D + 'ssf.java', 'utf8');
const ml4 = readFileSync(D + 'ml4.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ssf: 4 ctor deps + cx6', ssf.includes('public ssf(q75 q75Var, xrf xrfVar, vs4 vs4Var, cx6 cx6Var)'));
t('ssf: session Flow field', /public final sfb e;/.test(ssf));
t('b() returns ml4 = e field', ssf.includes('public final ml4 b()') && /return this\.e;/.test(ssf));
t('d(): 4-arg auth', ssf.includes('public final Object d(String str, c8c c8cVar, String str2, String str3, ff2 ff2Var)'));
t('e(): (String,String) suspend', ssf.includes('public final java.lang.Object e(java.lang.String'));
t('f(): calls xrf.g', ssf.includes('.g(r2, r1'));
t('e/f decompile-skipped', ssf.includes('ssf.e(java.lang.String, java.lang.String, ff2)') && ssf.includes('ssf.f(java.lang.String, java.lang.String, ff2)'));
t('ml4 is interface', /public interface ml4/.test(ml4));
t('ssf ≥7 suspend methods', (ssf.match(/public final (java\.lang\.)?Object [a-z]\(/g) || []).length >= 7);
const xrf = readFileSync(D + 'xrf.java', 'utf8');
t('xrf: backend client exists', /class xrf|interface xrf/.test(xrf));
console.log('ssf-auth replay: ' + n + '/10 checks green');
