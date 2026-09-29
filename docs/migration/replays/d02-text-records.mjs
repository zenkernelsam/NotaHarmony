// Phase 1107 — i4c/h4c apply record + uwc positioned element + xj2.f
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const i4c = R('i4c'), h4c = R('h4c'), uwc = R('uwc'), e4c = R('e4c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('i4c = iface', i4c.includes('interface i4c'));
t('h4c implements i4c', h4c.includes('implements i4c'));
t('h4c {ywc a, qo5 b}', h4c.includes('ywc a') && h4c.includes('qo5 b'));
t('h4c.getId()→qo5', h4c.includes('qo5 getId()'));
t('uwc extends ywc', uwc.includes('extends ywc'));
t('uwc {qo5 c, exc d}', uwc.includes('qo5 c') && uwc.includes('exc d'));
t('uwc {long e,f, Integer g}', uwc.includes('long e') && uwc.includes('long f') && uwc.includes('Integer g'));
t('e4c constructs uwc record', e4c.includes('new uwc('));
t('e4c h4c wrapper', e4c.includes('new h4c('));
t('xj2.f tombstone check', e4c.includes('xj2.f(') && e4c.includes('this.g.I'));
console.log('text-records replay: ' + n + '/10 checks green');
