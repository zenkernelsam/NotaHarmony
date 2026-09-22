// Phase 608 — 区域选区剔除 positionLocked 元素（fu1.b → jrh.a）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   fu1.java:35-48 — b(x09,set)：POSITION_LOCKED(ac4.Q=PRODUCTION 默认开)
//     时剔除 jrh.a(be5) 为真的元素；be5 解析失败或 jrh.a 为假则保留。
//   jrh.java:13-22 — a(be5)：oy0 块 → t()（positionLocked）；
//     m4d 形状 → cih.a && n5d.t()；其余（s06 笔迹）→ false。
//   cih.java:18-21 — a(m4d) = !n5d.y（可锁形状门控）。
//   uw2.java:73-75 — 矩形选完成：f(uh5) → b(锁剔除) → c(组扩展 ac4.V)。
//   vo2.java:171 — 套索完成同路径。
//   xtc.java:28,77 — 点按路径 a()/c() 直用 fu1.e，无 b 过滤——
//     锁定元素仍可点选（UNLOCK 可达）。
// Harmony：finalizeSelection 逐类 positionLocked 剔除（组扩展之前），
//   笔迹不剔除；点按路径不过滤。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const TOOL = 'note/src/main/ets/rendering/SelectionTool.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const tool = read(TOOL);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- finalizeSelection：四类元素的 positionLocked 剔除 ---
const fin = tool.slice(tool.indexOf('finalizeSelection(strokes'),
  tool.indexOf('finalizeSelection(strokes') + 4200);
check(fin.indexOf('const selectionPath') < fin.indexOf('for (const s of strokes)'),
  'selectionPath precedes the stroke loop');
// 笔迹循环不含 positionLocked 剔除（jrh.a(s06)=false）
const strokeLoop = fin.slice(fin.indexOf('for (const s of strokes)'),
  fin.indexOf('this.state.selectedStrokeIds = ids;'));
check(!strokeLoop.includes('positionLocked'),
  'strokes are never lock-filtered (jrh.a → false for s06)');
const shapeLoop = fin.slice(fin.indexOf('for (const shape of shapes)'),
  fin.indexOf('this.state.selectedShapeIds'));
check(shapeLoop.includes('shape.positionLocked === true'),
  'locked shapes skipped before the region hit test (n5d.t parity)');
const textLoop = fin.slice(fin.indexOf('for (const textBlock of textBlocks)'),
  fin.indexOf('this.state.selectedTextBlockIds'));
check(textLoop.includes('textBlock.positionLocked === true'),
  'locked text blocks skipped (oy0.t parity)');
const imageLoop = fin.slice(fin.indexOf('for (const image of images)'),
  fin.indexOf('this.state.selectedImageIds'));
check(imageLoop.includes('image.positionLocked === true'),
  'locked images skipped (oy0.t parity)');
const mathLoop = fin.slice(fin.indexOf('for (const math of mathBlocks)'),
  fin.indexOf('this.state.selectedMathIds'));
check(mathLoop.includes('math.positionLocked === true'),
  'locked math blocks skipped (oy0.t parity)');
// 剔除发生在 resolveOriginalGroupSelection 之前（f→b→c 次序）
check(fin.indexOf('positionLocked') < fin.indexOf('resolveOriginalGroupSelection'),
  'lock exclusion precedes group expansion (f → b → c order)');
// 注释锚点
check(fin.includes('fu1.b') && fin.includes('jrh.a'),
  'exclusion documents the fu1.b / jrh.a original path');

// --- 单元素选择路径不过滤（xtc.a/e 无 b）——点选锁定元素仍可解锁 ---
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const tapSelect = canvas.slice(canvas.indexOf('private applyTapSelect('),
  canvas.indexOf('private applyTapSelect(') + 1600);
check(!tapSelect.includes('positionLocked'),
  'tap-select path has no lock filter (xtc.a parity — unlock stays reachable)');

console.log(`D02_ORIGINAL_LOCK_REGION_FILTER_OK TOTAL=${n} FAILED=0`);
