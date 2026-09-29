// Phase 1038 — ze9 bundle header + a79 constants
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const ze9 = readFileSync(D + 'ze9.java', 'utf8');
const ye9 = readFileSync(D + 'ye9.java', 'utf8');
const a79 = readFileSync(D + 'a79.java', 'utf8');
const m09 = readFileSync(D + 'm09.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ze9 implements ye9', ze9.includes('implements ye9'));
t('ze9: 6 fields', (ze9.match(/public final (ttf|short|long) [a-f];/g) || []).length === 6);
t('ze9: 4 ttf + short + long', (ze9.match(/public final ttf [a-f];/g) || []).length === 4 && /public final short c;/.test(ze9) && /public final long e;/.test(ze9));
t('ze9: 6-arg ctor', ze9.includes('public ze9(ttf ttfVar, ttf ttfVar2, short s, ttf ttfVar3, long j, ttf ttfVar4)'));
t('ye9: header iface', /interface ye9|class ye9/.test(ye9));
t('a79: er6 L const', a79.includes('new er6(3)') || a79.includes('er6 L'));
t('a79: qed N + float P', a79.includes('qed N') && a79.includes('float P'));
t('m09.a builds ze9', m09.includes('new ze9('));
t('m09.a: r29 accessors', m09.includes('r4j.b(r29Var)') && m09.includes('r29Var.l()') && m09.includes('r29Var.j()'));
const r4j = readFileSync(D + 'r4j.java', 'utf8');
t('r4j: id extractors', /class r4j|interface r4j/.test(r4j));
console.log('ze9-header replay: ' + n + '/10 checks green');
