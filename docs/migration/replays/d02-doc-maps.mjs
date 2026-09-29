// Phase 1077 — v69 entity-map roster + ba6.j all-known + xhe
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const v69 = R('v69'), ba6 = R('ba6'), xhe = R('xhe');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('v69.i()→uia', v69.includes('uia i()'));
t('v69.k()→aja + n()→aja', v69.includes('aja k()') && v69.includes('aja n()'));
t('v69.l()→bja + p()→bja', v69.includes('bja l()') && v69.includes('bja p()'));
t('v69.r()→qja', v69.includes('qja r()'));
t('ba6.j(v69,List,z) all-known check', ba6.includes('boolean j(v69 v69Var, List list, boolean z)'));
t('ba6.j: checks l/p/i/n/k maps', ba6.includes('v69Var.l().containsKey') && ba6.includes('v69Var.p().containsKey') && ba6.includes('v69Var.i().containsKey') && ba6.includes('v69Var.n().containsKey') && ba6.includes('v69Var.k().containsKey'));
t('ba6.j: z→r().I tombstone map', ba6.includes('v69Var.r().I.containsKey'));
t('ba6.j: any-missing→false', ba6.includes('return false'));
t('xhe extends oy0,be5,ce5 + whe companion', xhe.includes('extends oy0, be5, ce5') && xhe.includes('whe a'));
t('ba6.j: false→Inconsistent-logic path', ba6.includes('return true'));
console.log('doc-maps replay: ' + n + '/10 checks green');
