// Phase 1204 — t76 consumer roles (ol4 FlowCollector + ls reconciler + ot3 motion)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ol4 FlowCollector emit', R('ol4.java').includes('emit('));
t('ls implements ol4', R('ls.java').includes('implements ol4'));
const ls = R('ls.java');
t('ls StrokeInput import', ls.includes('androidx.ink.strokes.StrokeInput'));
t('ls stroke-lifecycle warning', ls.includes('finished with a StrokeInput'));
t('ls link ClipData', ls.includes('newPlainText("link"'));
t('n03 implements ol4', R('n03.java').includes('implements ol4'));
t('e71 implements ol4', R('e71.java').includes('implements ol4'));
const ot3 = R('ot3.java');
t('ot3 TweenSpec vhf 120/150', ot3.includes('new vhf(120') && ot3.includes('new vhf(150'));
t('ot3 CubicBezierEasing 0.4,0,0.6,1', ot3.includes('0.4f, 0.0f, 0.6f, 1.0f'));
t('em1 composable host uz4', R('em1.java').includes('uz4'));
console.log('t76-consumers replay: ' + n + '/10 checks green');
