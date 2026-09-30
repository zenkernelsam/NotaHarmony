// Phase 1253 — od8 Modifier.Node base
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const od8 = R('od8.java');
t('od8 implements j73', od8.includes('implements j73'));
t('od8 I=this self + L=-1 kind', od8.includes('od8 I = this') && od8.includes('int L = -1'));
t('od8 K kind-set', od8.includes('int K'));
t('od8 M,N parent/child', od8.includes('od8 M') && od8.includes('od8 N'));
t('od8 P LayoutNode owner', od8.includes('ry8 P'));
t('od8 J coroutine scope', od8.includes('hi2 J'));
t('od8 attached multiple times guard', od8.includes('node attached multiple times'));
t('od8 detach not-attached guard', od8.includes('Cannot detach a node that is not attached'));
t('od8 ModifierNodeDetachedCancellation', od8.includes('ModifierNodeDetachedCancellationException'));
t('od8 detached multiple times guard', od8.includes('node detached multiple times'));
console.log('modifier-node replay: ' + n + '/10 checks green');
