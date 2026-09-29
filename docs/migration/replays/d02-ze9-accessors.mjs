// Phase 1039 — ze9 accessor→field map + led
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const ze9 = readFileSync(D + 'ze9.java', 'utf8');
const led = readFileSync(D + 'led.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ze9 a(): timestamp (e)', ze9.includes('public final long a()') && /a\(\)[^}]*return this\.e/.test(ze9));
t('ze9 c(): noteId (a)', ze9.includes('public final ttf c()') && /c\(\)[^}]*return this\.a/.test(ze9));
t('ze9 b(): d field', ze9.includes('public final ttf b()') && /b\(\)[^}]*return this\.d/.test(ze9));
t('ze9 d(): led(c) box', ze9.includes('public final led d()') && ze9.includes('new led(this.c)'));
t('ze9 e(): f field', ze9.includes('public final ttf e()') && /e\(\)[^}]*return this\.f/.test(ze9));
t('led: short value-class', /public final short a;/.test(led));
t('led: synthetic ctor', led.includes('public /* synthetic */ led(short s)'));
t('led: toString a(short)', led.includes('public static String a(short s)'));
t('ye9: overridden accessors', ze9.split('@Override').length - 1 >= 4);
const r29 = readFileSync(D + 'r29.java', 'utf8');
t('r29: bundle table (source)', /class r29|interface r29/.test(r29));
console.log('ze9-accessors replay: ' + n + '/10 checks green');
