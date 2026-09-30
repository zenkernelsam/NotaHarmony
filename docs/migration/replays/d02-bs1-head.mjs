// Phase 1153 — bs1 bundle head + l96 IO facade
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const bs1 = R('bs1'), l96 = R('l96'), modelA = readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/core/model/a.java','utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('bs1{short a version}', bs1.includes('final short a'));
t('bs1{int b capacity}', bs1.includes('final int b'));
t('bs1{AtomicInteger c counter}', bs1.includes('final AtomicInteger c'));
t('bs1 ctor(capacity,version)', bs1.includes('bs1(int i, short s)'));
t('bs1 c = AtomicInteger(capacity)', bs1.includes('new AtomicInteger(i)'));
t('l96.M(short)→bs1 factory', l96.includes('bs1 M(short s)') && l96.includes('new bs1(0, s)'));
t('l96.M0 InputStream→byte[]', l96.includes('byte[] M0(InputStream inputStream)'));
t('l96 8KB buffer copy', l96.includes('Math.max(8192, inputStream.available())'));
t('model.a uses l96.M bs1', modelA.includes('l96.M((short) 0)'));
t('bs1 equals/hashCode/toString', bs1.includes('equals(Object') && bs1.includes('hashCode()') && bs1.includes('toString()'));
console.log('bs1-head replay: ' + n + '/10 checks green');
