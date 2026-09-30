// Phase 1260 — mea/lea pencil splat-atlas model
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const mea = R('mea.java');
t('mea static ByteBuffer j', mea.includes('static final ByteBuffer j'));
t('mea k=sqrt(2) AA', mea.includes('Math.sqrt(2.0'));
t('mea lea a atlas', mea.includes('lea a'));
t('mea int b color', mea.includes('final int b'));
t('mea f,g,h,i pos/rot/size', mea.includes('float f') && mea.includes('float i'));
const lea = R('lea.java');
t('lea extends a atlas', lea.includes('extends a'));
const owd = R('owd.java');
t('owd List<mea> splats', owd.includes('mea') && owd.includes('List'));
t('owd splat List field', owd.match(/List/) && owd.includes('mea'));
const a = R('a.java');
t('a baked byte[] atlas', a.includes('byte[') || a.includes('byte[]'));
t('mea ByteBuffer nativeOrder', mea.includes('ByteOrder.nativeOrder()'));
console.log('splat-model replay: ' + n + '/10 checks green');
