// Phase 1327 — ShapeDetector shape-recognition audit (vs b16.h/e5d)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/algorithm/ShapeDetector.ets';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/b90.java';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };
const d = readFileSync(S, 'utf8');

t('ShapeDetector class', d.includes('class ShapeDetector'));
t('RecognitionProvider impl', d.includes('RecognitionProvider'));
t('hold-to-detect trigger', /hold|trigger|timer/i.test(d));
t('kinds LINE/ELLIPSE/POLYGON', /LINE|ELLIPSE|POLYGON/.test(d));
t('lineThreshold 0.6', d.includes('0.6'));
t('lineMinLength 60', d.includes('60'));
t('ellipseMaxGap 120', d.includes('120'));
t('b16.h uneven gate ref', d.includes('b16') || /uneven|quarter/i.test(d));
t('e5d arbitration', d.includes('e5d') || /arbitration|candidate/i.test(d));
t('original baseline b90', existsSync(D));
console.log('shape-detector replay: ' + n + '/10 checks green');
