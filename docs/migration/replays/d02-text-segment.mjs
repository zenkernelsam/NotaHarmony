// Phase 1133 — s3c styled text segment (dual-anchor span)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const s3c = R('s3c'), ry1 = R('ry1'), e4c = R('e4c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('s3c final class', s3c.includes('final class s3c'));
t('s3c {Set a,b}', s3c.includes('Set a') && s3c.includes('Set b'));
t('s3c CharSequence content', s3c.includes('CharSequence c'));
t('s3c dual exc f,g anchors', s3c.includes('exc f') && s3c.includes('exc g'));
t('s3c offset int e', s3c.includes('int e'));
t('s3c codepoint len (ry1.g or codePointCount)', s3c.includes('Character.codePointCount') && s3c.includes('ry1'));
t('s3c.a copy-with factory', s3c.includes('s3c a(s3c s3cVar'));
t('e4c.h builds s3c segments', e4c.includes('new s3c('));
t('ry1 CharSequence codepoint helpers', ry1.includes('CharSequence') && ry1.includes('int i(int i)') || ry1.includes('g()'));
t('s3c ctor 7-arg', s3c.includes('s3c(Set set, Set set2, CharSequence'));
console.log('text-segment replay: ' + n + '/10 checks green');
