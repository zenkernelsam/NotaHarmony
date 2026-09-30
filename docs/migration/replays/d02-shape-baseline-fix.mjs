// Phase 1352 — shape-detector baseline attribution fix
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const H = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/algorithm/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('b90 is AbstractSet not detector', readFileSync(D + 'b90.java', 'utf8').includes('AbstractSet'));
t('g5d = ShapeDetectorOutput', readFileSync(D + 'g5d.java', 'utf8').includes('ShapeDetectorOutput'));
t('g5d has confidence', readFileSync(D + 'g5d.java', 'utf8').includes('confidence'));
t('uf8 detector impl', readFileSync(D + 'uf8.java', 'utf8').includes('xf8'));
t('f5d 0.05f cluster', readFileSync(D + 'f5d.java', 'utf8').includes('0.05'));
t('h8d point', existsSync(D + 'h8d.java'));
t('mih math helper', existsSync(D + 'mih.java'));
const sd = readFileSync(H + 'ShapeDetector.ets', 'utf8');
t('harmony ShapeDetector', sd.includes('detect') || sd.includes('Shape'));
t('harmony confidence/threshold', sd.includes('Threshold') || sd.includes('confidence') || sd.includes('0.6'));
t('harmony DouglasPeucker', sd.includes('douglasPeucker') || sd.includes('DouglasPeucker'));
console.log('shape-baseline-fix replay: ' + n + '/10 checks green');
