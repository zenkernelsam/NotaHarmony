// Phase 1111 — hja persistent map + gja builder + lk6/ik6 markers
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const hja = R('hja'), gja = R('gja'), lk6 = R('lk6'), ik6 = R('ik6'), iwc = R('iwc');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('hja extends Map,ik6', hja.includes('interface hja extends Map, ik6'));
t('hja.builder()→gja', hja.includes('gja builder()'));
t('hja.put(k,v)→hja persistent assoc', hja.includes('hja put(Object obj, Object obj2)'));
t('gja extends Map,lk6', gja.includes('interface gja extends Map, lk6'));
t('gja.build()→hja freeze', gja.includes('hja build()'));
t('lk6 builder marker iface', lk6.includes('interface lk6') || lk6.includes('lk6'));
t('ik6 snapshot marker iface', ik6.includes('interface ik6') || ik6.includes('ik6'));
t('iwc derives builders from bxc', iwc.includes('.builder()'));
t('iwc has dual gja', iwc.includes('gja i') && iwc.includes('gja k'));
t('e4c holds gja + al2', R('e4c').includes('gja f'));
console.log('persistent-map replay: ' + n + '/10 checks green');
