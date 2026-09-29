// Phase 1053 — FlatBuffer write path: zwd registry + z0c map + builder API
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const R = f => readFileSync(D + f, 'utf8');
const zwd = R('defpackage/zwd.java'), z0c = R('defpackage/z0c.java'), apb = R('defpackage/apb.java'), a = R('com/google/flatbuffers/a.java');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('zwd: lazy serializer registry', zwd.includes('new pce(new z0c(21))'));
t('zwd: KClass→wx4 dispatch', zwd.includes('map.get(npbVar.b(cls))') && zwd.includes('wx4Var.invoke(xwdVar, aVar)'));
t('zwd: unknown→fail-loud', zwd.includes('rgc.b(') && zwd.includes('throw null'));
t('z0c case21: mx7 map + npb.b puts', z0c.includes('mx7Var.put(npbVar.b(') && z0c.includes('case 21:'));
t('z0c: inline ywd serializer (t/v/w/r)', z0c.includes('aVar2.t(4, 20)') && z0c.includes('aVar2.v(') && z0c.includes('aVar2.w(') && z0c.includes('aVar2.r()'));
t('z0c: ua0→yec serializer', z0c.includes('ua0.class') && z0c.includes('new yec('));
t('apb.Z: qed struct writer', apb.includes('int Z(qed qedVar, a aVar)') && apb.includes('aVar.t(4, 8)') && apb.includes('aVar.v(fC)') && apb.includes('aVar.v(fD)') && apb.includes('aVar.r()'));
t('a: prep/scalar/field/string API', a.includes('public final void t(') && a.includes('public final void v(int i, float f') || (a.includes('public final void b(byte b)') && a.includes('public final int l(CharSequence')));
t('a: j(slot,off) add-field', a.includes('public final void j(int i, int i2)'));
t('a: k(ByteBuffer)/l(CharSequence) create', a.includes('public final int k(ByteBuffer') && a.includes('public final int l(CharSequence'));
t('write helpers: apb/zwd/rr2 exist', [apb, zwd].every(s => s.includes('public static')) && R('defpackage/rr2.java').length > 0);
console.log('fb-write-path replay: ' + n + '/11 checks green');
