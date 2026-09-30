// Phase 1276 — mmf/njj/ft9/tr2 packed-ID + entity decode + GraphQL op
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const mmf = R('mmf.java');
t('mmf int value-class', mmf.includes('int I') && mmf.includes('Comparable'));
t('mmf unsigned a(i)', mmf.includes('4294967295'));
const njj = R('njj.java');
t('njj A(cee)→qo5 decoder', njj.includes('qo5 A(cee'));
t('njj j0 radix-toString', njj.includes('String j0(int i, long j)'));
t('njj Modifier helpers C/D', njj.includes('pd8 C(pd8') && njj.includes('pd8 D(pd8'));
const ft9 = R('ft9.java');
t('ft9 Operation id/name', ft9.includes('id()') && ft9.includes('name()') && ft9.includes('c()'));
const tr2 = R('tr2.java');
t('tr2 r24 adapters Set+Map', tr2.includes('implements r24') && tr2.includes('Set a') && tr2.includes('Map c'));
const qo5 = R('qo5.java');
t('qo5 id fields', qo5.includes('String a()') && qo5.includes('int d()'));
const o20 = R('o20.java');
t('o20 operation record', o20.includes('implements mj8'));
const gv = R('gv.java');
t('gv uses tr2 adapters', gv.includes('tr2') || gv.includes('ft9'));
console.log('id-encode-graphql replay: ' + n + '/10 checks green');
