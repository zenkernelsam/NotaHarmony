// Phase 1211 — vle Modifier.Node lifecycle (od8 Y0/Z0)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const od8 = R('od8.java');
t('od8 Y0/Z0 lifecycle', od8.includes('void Y0()') && od8.includes('void Z0()'));
t('od8 node-attach guards', od8.includes('node attached multiple times') && od8.includes('not attached'));
const n73 = R('n73.java');
t('n73 DelegatingNode g1(j73)', n73.includes('g1(j73') && n73.includes('extends od8'));
const vle = R('vle.java');
t('vle extends n73', vle.includes('extends n73'));
t('n73 extends od8', R('n73.java').includes('extends od8'));
t('vle.Y0 overrides od8', vle.includes('public final void Y0()'));
t('vle.Y0 registers joe.m', vle.includes('this.a0.m = this.s0'));
t('vle.Y0 g1(bq4) when editable', vle.includes('g1(this.i0)'));
t('vle.Z0 unregisters', vle.includes('this.a0.m = null'));
t('vle.M delegates u8e', vle.includes('this.j0.M()'));
console.log('vle-modifier-node replay: ' + n + '/10 checks green');
