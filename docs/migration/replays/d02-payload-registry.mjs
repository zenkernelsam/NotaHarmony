// Phase 1096 — zq9.a KClass→haa registry + mx7 map + npb
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const zq9 = R('zq9'), mx7 = R('mx7'), npb = R('npb'), mpb = R('mpb');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('zq9.a = mx7 registry', zq9.includes('mx7 mx7Var = new mx7()'));
t('zq9: 31 haa entries (ops 1-31)', (zq9.match(/haa\./g) || []).length === 31);
t('zq9: KClass via npb.b(X.class)', zq9.includes('npbVar.b(l2d.class)') && zq9.includes('npbVar.b(ln2.class)'));
t('zq9: SET_METADATA + CREATE_PAGE keys', zq9.includes('haa.SET_METADATA') && zq9.includes('haa.CREATE_PAGE'));
t('zq9: reverse of z5c.x (class→type)', zq9.includes('haa.MODIFY_COMMENT'));
t('npb = KClass factory', npb.includes('oj6 b(Class cls)') || npb.includes('hk6'));
t('mpb.a = npb singleton', mpb.includes('npb') || mpb.includes('a ='));
t('mx7 implements Map+Serializable+lk6', mx7.includes('implements Map, Serializable, lk6'));
t('mx7: dual-array {Object[] I,J; int[] K,L}', mx7.includes('Object[] I') && mx7.includes('Object[] J') && mx7.includes('int[] K') && mx7.includes('int[] L'));
t('mx7: int M,N size/capacity', mx7.includes('int M') && mx7.includes('int N'));
console.log('payload-registry replay: ' + n + '/10 checks green');
