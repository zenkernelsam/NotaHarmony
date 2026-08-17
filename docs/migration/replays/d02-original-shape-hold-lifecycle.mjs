import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const readRepo = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');
const readOriginal = name => fs.readFileSync(path.join(originalRoot, name), 'utf8').replaceAll('\r\n', '\n');

const y95 = readOriginal('y95.java');
const tc5 = readOriginal('tc5.java');
const z95 = readOriginal('z95.java');
const dzf = readOriginal('dzf.java');
const mw = readOriginal('mw.java');
const e5d = readOriginal('e5d.java');
const y90 = readOriginal('y90.java');
const a5g = readOriginal('a5g.java');
const zhh = readOriginal('zhh.java');
const s16 = readOriginal('s16.java');
const aih = readOriginal('aih.java');
const z4d = readOriginal('z4d.java');
const t06 = readOriginal('t06.java');
const i06 = readOriginal('i06.java');
const m06 = readOriginal('m06.java');
const b16 = readOriginal('b16.java');

const lifecycle = readRepo('note/src/main/ets/core/model/ShapeHoldLifecycle.ets');
const adjustment = readRepo('note/src/main/ets/core/model/ShapeHoldAdjustment.ets');
const detector = readRepo('note/src/main/ets/core/algorithm/ShapeDetector.ets');
const recognition = readRepo('note/src/main/ets/core/model/ShapeRecognition.ets');
const geometry = readRepo('note/src/main/ets/core/model/ShapeGeometry.ets');
const canvas = readRepo('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const lifecycleFixture = readRepo('note/src/test/ShapeHoldLifecycle.test.ets');
const adjustmentFixture = readRepo('note/src/test/ShapeHoldAdjustment.test.ets');
const detectorFixture = readRepo('note/src/test/ShapeDetector.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');

function pauseRestarts(points, threshold) {
  let anchor = null;
  const restarts = [];
  for (const point of points) {
    if (anchor === null || Math.hypot(point.x - anchor.x, point.y - anchor.y) >= threshold) {
      anchor = { ...point };
      restarts.push({ ...point });
    }
  }
  return restarts;
}

function shouldNormalizeCircle(major, minor) {
  const average = (major + minor) / 2;
  const ratio = minor / major;
  return ratio > 0.7 || (average < 30 && ratio > 0.5);
}

function adjustLineControl(start, oldEnd, newEnd, control) {
  const oldX = oldEnd.x - start.x;
  const oldY = oldEnd.y - start.y;
  const denominator = oldX * oldX + oldY * oldY;
  const controlX = control.x - start.x;
  const controlY = control.y - start.y;
  const parallel = (controlX * oldX + controlY * oldY) / denominator;
  const perpendicular = (controlY * oldX - controlX * oldY) / denominator;
  const newX = newEnd.x - start.x;
  const newY = newEnd.y - start.y;
  return {
    x: start.x + parallel * newX - perpendicular * newY,
    y: start.y + perpendicular * newX + parallel * newY,
  };
}

function scalePoint(point, anchor, scale) {
  return {
    x: anchor.x + (point.x - anchor.x) * scale,
    y: anchor.y + (point.y - anchor.y) * scale,
  };
}

const scheduleMethod = canvas.slice(
  canvas.indexOf('private scheduleShapeDetection(): void'),
  canvas.indexOf('private cancelShapeDetectionTimer(): void'));
const fittedScoreIndex = detector.indexOf('const fitConfidence: number = this.ellipseConfidence(');
const circleRuleIndex = detector.indexOf('if (minorMajorRatio > 0.7 ||');
const originalScoreIndex = y90.indexOf('float fA = m06Var.a(arrayList);');
const originalCircleRuleIndex = y90.indexOf('if (fMax2 / fMax > 0.7f || z)');

const restarts = pauseRestarts([
  { x: 0, y: 0 }, { x: 3, y: 4 }, { x: 7.9, y: 0 },
  { x: 8, y: 0 }, { x: 15.9, y: 0 }, { x: 16, y: 0 },
], 8);
const adjustedControl = adjustLineControl(
  { x: 0, y: 0 }, { x: 10, y: 0 }, { x: 10, y: 10 }, { x: 5, y: 2 });
const polygonAnchor = { x: 2, y: 2 };
const scaledPolygon = [
  { x: 0, y: 0 }, { x: 6, y: 0 }, { x: 0, y: 6 },
].map(point => scalePoint(point, polygonAnchor, 2));

const checks = [
  ['original hold callback waits exactly 500 ms',
    y95.includes('fag.B(500L, this)')],
  ['original handwriting slop defaults to 2 below API 34',
    dzf.includes('default float c()') && dzf.includes('return 2.0f;') &&
      mw.includes('if (Build.VERSION.SDK_INT >= 34)') && mw.includes('return 2.0f;')],
  ['original touch input uses ViewConfiguration scaled touch slop',
    mw.includes('return this.a.getScaledTouchSlop();')],
  ['original Down installs the initial pause-detection anchor',
    tc5.includes('this.f = this.b;')],
  ['original stylus mouse and eraser threshold is handwriting slop times four',
    tc5.includes('toolType2 == 2 || toolType2 == 3 || toolType2 == 4') &&
      tc5.includes('dzfVar.c() * 4.0f : dzfVar.f()')],
  ['original sub-slop Move keeps the current job and anchor',
    tc5.includes('if (fSqrt2 >=') && tc5.includes('return;\n                }\n                ArrayList')],
  ['original threshold crossing advances the anchor and cancels the previous job',
    tc5.includes('this.f = new sc5(motionEvent.getX(), motionEvent.getY()') &&
      tc5.includes('tqdVar.a(null);') && tc5.includes('this.g = null;')],
  ['original scheduler cancels the previous job before launching y95',
    z95.includes('tqdVar.a(null);') && z95.includes('new y95(ix4Var, ef2Var, 0)')],
  ['original recognizer accepts only confidence strictly greater than 0.2',
    e5d.includes('if (f4 > 0.2f)')],
  ['original ellipse is scored before near-circle normalization',
    originalScoreIndex >= 0 && originalCircleRuleIndex > originalScoreIndex],
  ['original near-circle rule uses ratio 0.7 or small-radius ratio 0.5',
    y90.includes('f3 < 30.0f && fMax2 / fMax > 0.5f') &&
      y90.includes('fMax2 / fMax > 0.7f || z') &&
      y90.includes('new m06(h8dVar3, f3, f3, 0.0f)')],
  ['original non-LINE adjustment waits until geometry anchor distance reaches 5',
    a5g.includes('zhh.e(h8dVarA2, h8dVar5) >= 5.0d')],
  ['original first accepted adjustment point becomes a stable origin',
    a5g.includes('if (((h8d) dk0Var.L) == null)') && a5g.includes('dk0Var.L = h8dVar5;')],
  ['original LINE moves its end from current minus first adjustment point',
    a5g.includes('mih.t(mih.u(h8dVar6, h8dVar5), h8dVar)')],
  ['original LINE control point is similarity-transformed with parallel and perpendicular terms',
    a5g.includes('((fD3 * fD2) + (fC2 * fC)) / f2') &&
      a5g.includes('((fD3 * fC) + ((-fC2) * fD2)) / f2')],
  ['original ELLIPSE uniformly scales both radii and retains rotation',
    a5g.includes('zhh.e(h8dVarA, h8dVar5) / dE') &&
      a5g.includes('((double) m06Var.f) * dE2') &&
      a5g.includes('double d4 = m06Var.j')],
  ['original polygon anchor is the average vertex and adjustment is uniform scale',
    zhh.includes('d3 / ((double) list.size())') &&
      zhh.includes('d2 / ((double) list.size())') &&
      zhh.includes('e(h8dVarB, h8dVar3) / dE')],
  ['original recognizer exposes all eight internal classifier kinds',
    ['LINE', 'ARROW', 'SQUARE', 'RECTANGLE', 'TRIANGLE', 'POLYGON', 'ELLIPSE', 'BEZIERGON']
      .every((name, index) => s16.includes(`new s16("${name}", ${index})`))],
  ['original persisted ShapeDefinition union is only NONE LINE POLYGON and NORMAL_SHAPE',
    z4d.includes('NONE((byte) 0)') && z4d.includes('LINE((byte) 1)') &&
      z4d.includes('POLYGON((byte) 2)') && z4d.includes('NORMAL_SHAPE((byte) 3)') &&
      !z4d.includes('ARROW') && !z4d.includes('BEZIERGON')],
  ['original LINE and ARROW share t06 while the final arrow is a SINGLE line head',
    t06.includes('public final s16 h;') && t06.includes('super(s16Var);') &&
      t06.includes('s16.J') &&
      /r16Var instanceof t06[\s\S]*?new s4d\(z4d\.LINE,[\s\S]*?t06Var\.h\.ordinal\(\)[\s\S]*?z90\.SINGLE/.test(aih)],
  ['original ELLIPSE maps m06 to the sole NORMAL_SHAPE definition',
    m06.includes('super(s16.L);') &&
      /r16Var instanceof m06[\s\S]*?new t4d\(z4d\.NORMAL_SHAPE/.test(aih)],
  ['original POLYGON family maps b16 including square rectangle and triangle subclasses to POLYGON',
    b16.includes('public class b16 extends r16') && b16.includes('super(s16.K);') &&
      /r16Var instanceof b16[\s\S]*?new u4d\(z4dVar, vaj\.a\(arrayList2\)\)/.test(aih)],
  ['original BEZIERGON flattens i06 control geometry into the final POLYGON definition',
    i06.includes('super(s16.M);') && i06.includes('return this.e.a();') &&
      /r16Var instanceof i06[\s\S]*?new u4d\(z4dVar, vaj\.a\(arrayList\)\)/.test(aih)],
  ['Harmony exposes the exact delay and independent handwriting/touch slop rules',
    lifecycle.includes('ORIGINAL_SHAPE_HOLD_DELAY_MS: number = 500') &&
      lifecycle.includes('ORIGINAL_SHAPE_HOLD_HANDWRITING_SLOP_MULTIPLIER: number = 4') &&
      lifecycle.includes('ORIGINAL_SHAPE_HOLD_FALLBACK_HANDWRITING_SLOP: number = 2')],
  ['Harmony labels the touch slop as a platform fallback rather than an original constant',
    lifecycle.includes('HARMONY_SHAPE_HOLD_FALLBACK_TOUCH_SLOP: number = 8') &&
      lifecycle.includes('not an Android 1.0.3 constant')],
  ['Harmony pause tracker preserves the anchor below threshold and advances at equality',
    lifecycle.includes('if (Math.sqrt(dx * dx + dy * dy) < threshold)') &&
      lifecycle.includes('this.anchor = this.clonePoint(point);')],
  ['Harmony Canvas uses screen-space source-tool slop before scheduling',
    canvas.includes('event.sourceTool === SourceTool.Pen') &&
      canvas.includes('event.sourceTool === SourceTool.MOUSE') &&
      canvas.includes('this.shapeHoldPauseTracker.update({ x: touch.x, y: touch.y }, threshold)')],
  ['Harmony only restarts detection after a pause-anchor threshold crossing',
    canvas.includes('private updateShapeHold(event: TouchEvent, touch: TouchObject): void') &&
      canvas.includes('if (this.shapeHoldPauseTracker.update({ x: touch.x, y: touch.y }, threshold))')],
  ['Harmony timer callback clears its timer identity and uses the original constant',
    scheduleMethod.includes('this.shapeHoldTimer = -1;') &&
      scheduleMethod.includes('ORIGINAL_SHAPE_HOLD_DELAY_MS')],
  ['Harmony scheduler no longer clears an already snapped Shape',
    !scheduleMethod.includes('this.heldShapes = []')],
  ['Harmony begins one adjustment session after successful recognition',
    scheduleMethod.includes('this.shapeHoldAdjustment.begin(attempt.shapes)') &&
      scheduleMethod.includes('this.heldShapes = attempt.shapes')],
  ['Harmony Move adjusts an active Shape instead of restarting recognition',
    canvas.includes('if (this.shapeHoldAdjustment.isActive()) {\n      this.updateHeldShapeAdjustment(touch);\n      return;')],
  ['Harmony Up sends the final point through adjustment before committing Shape',
    canvas.indexOf('this.updateHeldShapeAdjustment(finalTouch);') <
      canvas.indexOf('const finalShapes: ShapeElement[] = this.heldShapes')],
  ['Harmony cancel page switch and disappear share complete hold-state reset',
    canvas.includes('private resetShapeHoldState(): void') &&
      canvas.includes('private cancelActiveInteraction(): void {\n    const heldShapeCleared') &&
      canvas.includes('aboutToDisappear(): void') && canvas.includes('this.resetShapeHoldState();')],
  ['Harmony confidence gate is strict and defaults to original 0.2',
    detector.includes('ORIGINAL_SHAPE_RECOGNITION_CONFIDENCE_THRESHOLD: number = 0.2') &&
      detector.includes('best.confidence <= this.config.confidenceThreshold')],
  ['Harmony documents the still-open arrow and curved classifier provider gap',
    detector.includes('主动启发式仍只分类普通 LINE、ELLIPSE 与开放/闭合 POLYGON') &&
      detector.includes('箭头/曲线分类继续作为显式 provider 差距')],
  ['Harmony scores fitted ellipse before applying the original circle rule',
    fittedScoreIndex >= 0 && circleRuleIndex > fittedScoreIndex],
  ['Harmony implements both original near-circle branches and average radius',
    detector.includes('minorMajorRatio > 0.7') &&
      detector.includes('averageRadius < 30 && minorMajorRatio > 0.5') &&
      detector.includes('rx = averageRadius;') && detector.includes('rotation = 0;')],
  ['Harmony LINE adjustment uses the original stable non-cumulative control transform',
    adjustment.includes('base.end.x + current.x - first.x') &&
      adjustment.includes('const parallel: number =') &&
      adjustment.includes('const perpendicular: number =')],
  ['Harmony non-LINE adjustment uses a 5 px gate and stable distance ratio',
    adjustment.includes('ORIGINAL_SHAPE_HOLD_ADJUSTMENT_MIN_DISTANCE: number = 5') &&
      adjustment.includes('this.distance(resolvedAnchor, point) / initialDistance')],
  ['Harmony adjustment clones Shapes so identity arrow transform and metadata survive',
    adjustment.includes('cloneShapeElement(shape)') &&
      geometry.includes('arrowHead: shape.arrowHead') &&
      geometry.includes('originalInkEffects: shape.originalInkEffects') &&
      geometry.includes('originalCreate: cloneOriginalShapeCreate(shape)')],
  ['Harmony keeps multi-definition results atomic and uses an aggregate anchor',
    recognition.includes('one unsupported element rejects the whole replacement') &&
      adjustment.includes('this.aggregateAnchor(this.baseShapes)')],
  ['ArkTS fixtures cover lifecycle adjustment confidence circles metadata and reset',
    lifecycleFixture.includes('sub-slop jitter') &&
      adjustmentFixture.includes('similarity-transforms controls') &&
      adjustmentFixture.includes('multi-definition result together') &&
      detectorFixture.includes('strictly greater than the configured original gate') &&
      detectorFixture.includes('small ellipse above the original 0.5 ratio exception')],
  ['new ArkTS fixtures are registered in the executed suite',
    fixtureList.includes("import shapeHoldLifecycleTest from './ShapeHoldLifecycle.test'") &&
      fixtureList.includes("import shapeHoldAdjustmentTest from './ShapeHoldAdjustment.test'") &&
      fixtureList.includes('shapeHoldLifecycleTest();') && fixtureList.includes('shapeHoldAdjustmentTest();')],
  ['numeric pause replay restarts only at 0 8 and 16 pixels',
    restarts.length === 3 && restarts[0].x === 0 && restarts[1].x === 8 && restarts[2].x === 16],
  ['numeric circle replay matches both original branches without widening the large-ellipse rule',
    shouldNormalizeCircle(80, 60) && shouldNormalizeCircle(28, 17) &&
      !shouldNormalizeCircle(80, 48)],
  ['numeric LINE replay similarity-transforms the control point',
    Math.abs(adjustedControl.x - 3) < 1e-9 && Math.abs(adjustedControl.y - 7) < 1e-9],
  ['numeric polygon replay scales around the average vertex without drift',
    scaledPolygon[0].x === -2 && scaledPolygon[0].y === -2 &&
      scaledPolygon[1].x === 10 && scaledPolygon[1].y === -2 &&
      scaledPolygon[2].x === -2 && scaledPolygon[2].y === 10],
];

for (const [name, ok] of checks) {
  assert.ok(ok, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

console.log(`D02_ORIGINAL_SHAPE_HOLD_LIFECYCLE_OK TOTAL=${checks.length} FAILED=0`);
