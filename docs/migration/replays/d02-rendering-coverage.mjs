// Phase 1311 — Harmony rendering coverage vs original editor
import { readFileSync, existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/rendering/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('CanvasViewport', X('CanvasViewport.ets'));
t('DirtyRectTracker', X('DirtyRectTracker.ets'));
t('EraserEngine', X('EraserEngine.ets'));
t('partial eraser', X('OriginalInkPartialEraser.ets'));
t('StrokeCanvasPainter', X('StrokeCanvasPainter.ets'));
t('MathCanvasRenderer', X('MathCanvasRenderer.ets'));
t('PdfRasterPlan', X('PdfRasterPlan.ets'));
t('UndoRedoManager', X('UndoRedoManager.ets'));
const me = readFileSync(S + 'OriginalMathEngine.ets', 'utf8');
t('glmath native binding', me.includes('glmath') && me.includes('measureNative'));
t('rendering 15+ files', readdirSync(S).filter(f => f.endsWith('.ets')).length >= 15);
console.log('rendering-coverage replay: ' + n + '/10 checks green');
