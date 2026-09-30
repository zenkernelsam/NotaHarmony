// Phase 1250 — Modifier.Node editor family
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('vle n73 11 ifaces', R('vle.java').includes('implements lo3, cma, mvc, o65, ara, jm6, q52, rd8, sn9, kv6, mp4'));
t('k2 n73 8 ifaces', R('k2.java').includes('implements ara, jm6, mvc, vff, q52, sn9, pz5, b25'));
t('bq4 n73 5 ifaces', R('bq4.java').includes('implements mvc, o65, q52, sn9, vff'));
t('gn3 n73 4 ifaces', R('gn3.java').includes('implements ara, pz5, q52, b25'));
t('eje n73 2 ifaces', R('eje.java').includes('implements q52, qie'));
t('u8e od8 3 ifaces', R('u8e.java').includes('implements bra, r93, ara'));
t('ol3 od8 3 ifaces', R('ol3.java').includes('implements vff, pl3, kv6'));
t('bk5 od8 ara', R('bk5.java').includes('extends od8 implements ara'));
t('ara shared input iface', R('ara.java').includes('extends j73'));
const n73 = R('n73.java');
t('n73 DelegatingNode extends od8', n73.includes('extends od8'));
console.log('node-family replay: ' + n + '/10 checks green');
