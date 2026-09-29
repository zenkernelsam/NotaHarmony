// Phase 1037 — x09 document model + m09 companion
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const x09 = readFileSync(D + 'x09.java', 'utf8');
const m09 = readFileSync(D + 'm09.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('x09: marker iface', /public interface x09/.test(x09) && x09.trim().split('\n').length < 15);
t('x09: m09 companion', x09.includes('public static final m09 a = m09.a'));
t('m09: qed default size', m09.includes('qed b') && m09.includes('a79.N'));
t('m09: 768 scale factor', m09.includes('/ 768.0') || m09.includes('/768'));
t('m09: vy7 default margins', m09.includes('vy7 d') && m09.includes('a79.O'));
t('m09: hu1 default color lazy', m09.includes('hu1 e') && m09.includes('tu1.a'));
t('m09: nz9 via vv7.f', m09.includes('nz9 f') && m09.includes('vv7.f('));
t('m09.a: r29→model materializer', m09.includes('public static Object a(r29 r29Var, cl9 cl9Var)'));
t('m09.a: ze9 header + lv2.T ops', m09.includes('new ze9(') && m09.includes('lv2.T(r29Var)'));
const a79 = readFileSync(D + 'a79.java', 'utf8');
t('a79: constants registry', /class a79|interface a79/.test(a79) && a79.includes('N'));
console.log('document-model replay: ' + n + '/10 checks green');
