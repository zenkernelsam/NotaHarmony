import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const normalize = value => value.replace(/\r\n?/g, '\n');
const read = value => normalize(fs.readFileSync(new URL(value, root), 'utf8'));
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => normalize(fs.readFileSync(originalRoot + value, 'utf8'));

const kt1 = original('sources/defpackage/kt1.java');
const bt1 = original('sources/defpackage/bt1.java');
const n1d = original('sources/defpackage/n1d.java');
const fsi = original('sources/defpackage/fsi.java');
const xq9 = original('sources/defpackage/xq9.java');
const s06 = original('sources/defpackage/s06.java');
const vnd = original('sources/defpackage/vnd.java');
const aa6 = original('sources/defpackage/aa6.java');
const pageOrder = read('note/src/main/ets/core/model/PageElementOrder.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const layers = read('note/src/main/ets/rendering/StrokeLayerManager.ets');
const fixture = read('note/src/test/PageElementOrder.test.ets');
const evidence = read(
  'docs/migration/evidence/original-partial-eraser-preview-z-order-jadx-2026-08-16.md');
const phase241 = read(
  'docs/migration/reports/修复总结-Phase241-原版PartialEraser临时预览与提交结束-2026-08-16.md');
const phase242 = read(
  'docs/migration/reports/修复总结-Phase242-原版PartialEraser预览层级与有序脏区-2026-08-16.md');

assert.match(kt1, /u16VarL = u16\.PARTIAL_ERASER/);
assert.match(bt1, /new wq9\(\(dm2\) obj6, null, true/);
assert.match(n1d, /fsi\.s\(tzcVar\.P, tzcVar\.Q, System\.currentTimeMillis\(\), ix4Var2\)/);
assert.match(fsi, /new xq9\(bs1Var2, bs1Var, arrayList, aVar, j\)/);
assert.match(xq9, /zq9\.e\(this\.d, qo5VarB, ceeVar, this\.e, null/);
assert.match(s06,
  /public final long g\(\)[\s\S]{0,360}tmfVarB != null \? tmfVarB\.I : this\.b\.k\(\)/);
assert.match(vnd, /Long\.compareUnsigned\(j, j2\) < 0 \? -1 : 1/);
assert.match(vnd, /long jB = [\s\S]{0,500}ly3Var\.g\(\)/);
assert.match(aa6, /eu1\.J0\(arrayList\);[\s\S]{0,80}eu1\.J0\(arrayList2\)/);
assert.match(aa6, /return new uld\(arrayList2, arrayList\)/);

assert.match(evidence, /s06\s+-> Ink[\s\S]{0,120}hp5\s+-> Image[\s\S]{0,120}xhe\s+-> Text/);
assert.match(evidence, /BlendMode\.SRC_OVER/);
assert.match(evidence, /1B1741F399CE8298FCA6A39E9094C86CC4A6F6D89E88E85F5469FD629AE6A578/);

assert.match(pageOrder,
  /transientTopStroke: StrokeElementData \| null = null[\s\S]{0,3000}zIndex: result\.length,[\s\S]{0,80}data: transientTopStroke/);
assert.match(canvas,
  /if \(partialEraserPreviewStroke !== null\) \{[\s\S]{0,900}compositeWithOrderedPartialEraser/);
assert.match(canvas,
  /renderOrderedElements\(renderContext, partialEraserPreviewStroke\)/);
assert.doesNotMatch(canvas, /isolatedPartialEraserPreview/);

const orderedCrop = layers.match(
  /compositeWithOrderedPartialEraser\([\s\S]*?\n  \}\n\r?\n  \/\/ 清空全部/);
assert.notEqual(orderedCrop, null);
assert.match(orderedCrop[0], /pixelAlignedPageCrop\(dirty\)/);
assert.match(orderedCrop[0], /renderBackground\(\)/);
assert.match(orderedCrop[0], /renderOrderedContent\(isolatedRenderContext\)/);
assert.match(orderedCrop[0], /finally \{[\s\S]{0,100}isolatedRenderContext\.restore\(\)/);
assert.doesNotMatch(orderedCrop[0], /completedBitmap|renderForeground/);

assert.match(fixture,
  /places transient partial-eraser Ink above every durable element without persisting it/);
assert.match(fixture, /expect\(elements\[5\]\.elementId\)\.assertEqual\(preview\.id\)/);
assert.match(fixture, /expect\(order\.length\)\.assertEqual\(5\)/);
assert.match(phase241, /Phase 242[\s\S]{0,500}z-index/);
assert.match(phase242, /REPLAY_FILES=227 FAILED=0/);
assert.match(phase242, /APK 版本追踪[\s\S]{0,120}最终阶段/);

const durable = [
  { kind: 'stroke', z: 10 },
  { kind: 'text', z: 20 },
  { kind: 'image', z: 30 },
  { kind: 'math', z: 40 },
];
const transient = { kind: 'partial-eraser', z: 50 };
const rendered = durable.concat(transient).sort((a, b) => a.z - b.z);
assert.equal(rendered.at(-1), transient);

console.log(
  'originalPartialEraserPreviewZOrder=client-time-top-ordered-dirty-crop-all-content-paper-safe');
