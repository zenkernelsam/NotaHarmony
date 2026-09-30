// Phase 1278 — i9h/s7h/g9h/h9h protobuf-lite infra
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const h9h = R('h9h.java');
t('h9h RawMessageInfo z6h+String+Object[]', h9h.includes('z6h a') && h9h.includes('String b') && h9h.includes('Object[] c'));
t('h9h flags int d', h9h.includes('int d'));
const g9h = R('g9h.java');
t('g9h a7h RandomAccess list', g9h.includes('extends a7h implements RandomAccess'));
t('g9h Object[] backing', g9h.includes('Object[] J') && g9h.includes('int K'));
const s7h = R('s7h.java');
t('s7h ExtensionRegistryLite', s7h.includes('volatile s7h a') && s7h.includes('static final s7h b'));
const i9h = R('i9h.java'), e9h = R('e9h.java');
t('i9h Schema iface', i9h.includes('interface i9h'));
t('e9h internal iface', e9h.includes('interface e9h'));
const z6h = R('z6h.java');
t('z6h.b(i9h) writeTo', z6h.includes('int b(i9h'));
const z7h = R('z7h.java');
t('z7h parseFrom s7h', z7h.includes('s7h'));
const x7h = R('x7h.java');
t('x7h s7h mergeFrom', x7h.includes('s7h'));
console.log('proto-infra replay: ' + n + '/10 checks green');
