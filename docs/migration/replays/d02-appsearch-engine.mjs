// Phase 1025 — b50 AppSearch engine impl
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const b50 = readFileSync(D + 'b50.java', 'utf8');
const f63 = readFileSync(D + 'f63.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('b50 implements clc', /class b50 implements clc|b50 implements/.test(b50) || b50.includes('clc'));
t('b50: Mutex', b50.includes('public final em8 b = fm8.a()'));
t('getName=appsearch', b50.includes('return "appsearch"'));
t('ctor f63 dep', b50.includes('public b50(f63 f63Var)'));
t('d(): note-scoped search', b50.includes('public final Serializable d(ttf ttfVar, String str, mlc mlcVar'));
t('g(): global search', b50.includes('public final Object g(String str, mlc mlcVar'));
t('i(): Serializable detail', b50.includes('public final java.io.Serializable i(java.lang.String'));
t('f63 extends wc6', /interface f63 extends wc6/.test(f63));
const d6c = readFileSync(D + 'd6c.java', 'utf8');
t('d6c: room-fts5 name', d6c.includes('"room-fts5"'));
const vmc = readFileSync(D + 'vmc.java', 'utf8');
t('vmc: clc injected + name cmp', vmc.includes('public final clc b;') && vmc.includes('getName()') && vmc.includes('ba6.o'));
console.log('appsearch-engine replay: ' + n + '/10 checks green');
