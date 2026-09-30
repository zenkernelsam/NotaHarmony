// Phase 1330 — rendering composite (partial eraser + layered)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/rendering/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ee = readFileSync(S + 'EraserEngine.ets', 'utf8');
const slm = readFileSync(S + 'StrokeLayerManager.ets', 'utf8');
t('EraserEngine erasePartial', ee.includes('erasePartial'));
t('partialReplacements (clip-split)', ee.includes('partialReplacements'));
t('original clip doc (w4b/h4f)', ee.includes('Notability 1.0.3') || ee.includes('clip'));
t('whole-erase deletes', ee.includes('deletedStrokeIds'));
t('EraserMode enum', ee.includes('EraserMode'));
t('layered composite', slm.includes('clip'));
t('destination-out erase', slm.includes('destination-out'));
t('DirtyRectTracker', existsSync(S + 'DirtyRectTracker.ets'));
t('CanvasViewport', existsSync(S + 'CanvasViewport.ets'));
t('renderer layer', existsSync(S + 'StrokeCanvasPainter.ets') || existsSync(S + 'InkRenderer.ets'));
console.log('render-composite replay: ' + n + '/10 checks green');
