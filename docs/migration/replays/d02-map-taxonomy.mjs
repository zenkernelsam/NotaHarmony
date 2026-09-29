// Phase 1105 — *ja/*ia map taxonomy: via builders, vz snapshots, jja hja-view
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const aja = R('aja'), bja = R('bja'), qja = R('qja'), jja = R('jja'),
      uia = R('uia'), tia = R('tia');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('aja extends via Map builder', aja.includes('extends via implements Map, ik6'));
t('tia extends via Map builder', tia.includes('extends via implements Map, ik6'));
t('bja extends vz snapshot', bja.includes('extends vz implements Map, ik6'));
t('bja.W0(wia)→via builder fork', bja.includes('via W0(wia wiaVar)'));
t('uia extends vz snapshot', uia.includes('extends vz implements Map, ik6'));
t('jja abstract Map,ik6 over hja', jja.includes('abstract class jja implements Map, ik6') && jja.includes('hja I'));
t('jja read-only: clear throws', jja.includes('UnsupportedOperationException'));
t('qja extends jja', qja.includes('extends jja'));
t('builders implement Map+ik6', aja.includes('Map, ik6') && tia.includes('Map, ik6'));
t('snapshots implement Map+ik6', bja.includes('Map, ik6') && uia.includes('Map, ik6') && qja.includes('jja'));
console.log('map-taxonomy replay: ' + n + '/10 checks green');
