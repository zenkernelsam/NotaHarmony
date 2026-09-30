// Phase 1247 — iqa/oqa/jqa pointer-input data
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const iqa = R('iqa.java');
t('iqa List<oqa> a + hc0 b', iqa.includes('final List a') && iqa.includes('final hc0 b'));
t('iqa classification ints c,d,e', iqa.includes('final int c') && iqa.includes('final int e'));
t('iqa actionMasked classify', iqa.includes('getActionMasked()'));
t('iqa a()->MotionEvent', iqa.includes('MotionEvent a()'));
const oqa = R('oqa.java');
t('oqa id/uptime/position longs', oqa.includes('final long a') && oqa.includes('final long c'));
t('oqa pressed boolean', oqa.includes('final boolean d'));
t('oqa pressure float', oqa.includes('final float e'));
t('oqa previousUptime/Position', oqa.includes('final long f') && oqa.includes('final long g'));
t('oqa type int i', oqa.includes('final int i'));
const jqa = R('jqa.java');
t('jqa PointerEventType I,J,K', jqa.includes('jqa I') && jqa.includes('jqa K'));
console.log('pointer-data replay: ' + n + '/10 checks green');
