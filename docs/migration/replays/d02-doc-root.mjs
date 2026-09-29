// Phase 1069 — v69 doc root + *ja/*ia causal-collection family
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const v69 = R('v69'), ija = R('ija'), via = R('via'), w4 = R('w4');
const bja = R('bja'), uia = R('uia'), kja = R('kja'), pja = R('pja'), qja = R('qja');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('v69: 7 metadata fqb regs (v..C)', (v69.match(/public final fqb [v-zA-C];/g) || []).length >= 7);
t('v69: e4c entity collection', v69.includes('public e4c e'));
t('v69: *ja/*ia collection fields', v69.includes('qja D') && v69.includes('bja E') && v69.includes('uia G') && v69.includes('lia q'));
t('via: LinkedHashMap causal base', via.includes('LinkedHashMap'));
t('ija: Map+ik6 impl w/ LinkedHashMap J', ija.includes('implements Map, ik6') && ija.includes('LinkedHashMap J'));
t('w4: AbstractSet base', w4.includes('extends AbstractSet'));
t('bja,uia extend vz (set-family)', bja.includes('extends vz') && uia.includes('extends vz'));
t('kja,pja extend ija (map-family)', kja.includes('extends ija') && pja.includes('extends ija'));
t('qja extends jja', qja.includes('extends jja'));
t('v69: ny3+a79+jm5 model deps', v69.includes('ny3 c') && v69.includes('a79 a') && v69.includes('jm5 d'));
console.log('doc-root replay: ' + n + '/10 checks green');
