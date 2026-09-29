// Phase 1090 — e4c text container (exc anchors + UTF-8 decode)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const e4c = R('e4c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('e4c implements o4c', e4c.includes('implements o4c'));
t('e4c: ArrayList c members', e4c.includes('public ArrayList c'));
t('e4c: exc anchor via au1.c1(gxc)', e4c.includes('(exc) au1.c1(gxcVar)'));
t('e4c: s3c text segment ctor', e4c.includes('new s3c(set2, set3'));
t('e4c: swc anchor navigation', e4c.includes('swcVar.d(new hr5())'));
t('e4c: UTF-8 CharsetDecoder', e4c.includes('StandardCharsets.UTF_8.newDecoder()'));
t('e4c: REPORT on malformed/unmappable', e4c.includes('onMalformedInput') && e4c.includes('onUnmappableCharacter'));
t('e4c: char[8192] decode buffer', e4c.includes('new char[8192]'));
t('e4c: m4c.D copy-with materialize', e4c.includes('m4c.D(this.b'));
t('e4c: gja f + al2 g stores', e4c.includes('gja f') && e4c.includes('al2 g'));
console.log('text-container replay: ' + n + '/10 checks green');
