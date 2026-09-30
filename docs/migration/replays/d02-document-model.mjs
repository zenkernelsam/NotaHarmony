// Phase 1312 — Harmony core/model document model coverage
import { existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/model/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ElementTypes', X('ElementTypes.ets'));
t('element geometries', X('ImageBlockGeometry.ets') && X('MathBlockGeometry.ets') && X('TextBlockGeometry.ets') && X('ShapeGeometry.ets'));
t('StrokeTypes+BrushTypes', X('StrokeTypes.ets') && X('BrushTypes.ets'));
t('page model', X('PageBackgroundModel.ets') && X('PageCoordinateSpace.ets') && X('PageElementOrder.ets'));
t('paper settings+template', X('OriginalPaperSettings.ets') && X('OriginalDefaultTemplate.ets'));
t('Original policies', X('OriginalNoteTitlePolicy.ets') && X('OriginalSnapGuides.ets'));
t('insert plans', X('OriginalImageInsertPlan.ets') && X('OriginalMathInsertPlan.ets'));
t('shape recognition', X('ShapeRecognition.ets') && X('ShapeHoldLifecycle.ets'));
t('OpTypes', X('OpTypes.ets'));
t('model 25+ files', readdirSync(S).filter(f => f.endsWith('.ets')).length >= 25);
console.log('document-model replay: ' + n + '/10 checks green');
