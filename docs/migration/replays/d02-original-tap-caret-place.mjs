// Phase 609 — 文本块按下点光标定位（sqa / rej.i 对齐）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dl1.java:327-330 — itc 单元素选区命中自身且为 xhe（文本块）→
//     new ttc(blockId, jE)（按下点世界坐标入事件）。
//   uw2.java:138-151 — case4(ttc)：xtc.d(new qke(ttc.a), true, z)
//     激活该块文本编辑器；随后 yqaVar.g.m(new sqa(
//     rej.i(zn9.f(j, uubVar.f), uubVar.e), 0)) —— zn9.f 世界点→局部、
//     rej.i 布局偏移命中，光标无条件定位到按下字符处（覆盖挂起光标）。
//   uke.java:258-268 — qke 分支：uke.p 按块 id 取 ake 会话激活。
// Harmony：caretIndexAtPoint = rej.i/getOffsetForPosition 等价
//   （最近行钳制 + 半字宽拆分）；beginTextEditingAt 激活后以
//   tapCaret 覆盖挂起光标；TextBlockOverlay onAppear 用
//   caretPosition 落位。链接命中仍优先于编辑激活（tqa 等价）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const renderer = read('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- caretIndexAtPoint：rej.i 等价（世界点 → 布局偏移） ---
const ci = renderer.slice(renderer.indexOf('caretIndexAtPoint(element'),
  renderer.indexOf('private characterIndexAt('));
check(ci.includes('inverseTransformPoint(worldPoint, element)'),
  'world point maps into block-local space first (zn9.f parity)');
check(ci.includes('layoutLines(ctx, characters, characterStyles, element)'),
  'uses the same layoutLines pass as linkAtPoint');
check(ci.includes('bestDistance') && ci.includes('bandTop - local.y'),
  'y axis clamps to the nearest line band (sqa nearest-line semantics)');
check(ci.includes('this.characterIndexAt(ctx, characters'),
  'x axis resolves through characterIndexAt (half-width split)');
check(ci.includes('index === null ? bestLine.end : index'),
  'past-line-end clamps to line.end');
check(ci.includes('element.richText.length === 0') && ci.includes('return 0'),
  'empty text resolves to caret 0');

// --- beginTextEditingAt：qke 激活 + sqa 光标定位次序 ---
const be = canvas.slice(canvas.indexOf('private beginTextEditingAt(position'),
  canvas.indexOf('private toggleCheckboxMarkerAt('));
check(be.indexOf('suspendedCaretByBlock.get(this.textBlocks[i].id)') <
  be.indexOf('caretIndexAtPoint'),
  'suspended session resolves before tap-caret placement (qke then sqa)');
check(be.includes('this.textRenderer.caretIndexAtPoint('),
  'tap position maps to a caret index via the renderer');
check(be.includes('this.textEditingRestoreCaret = tapCaret') &&
  be.includes('this.editingCaretOffset = tapCaret'),
  'tap caret overrides the suspended caret (sqa unconditional)');
check(be.indexOf('tapCaret') < be.indexOf('this.textEditing = true'),
  'caret resolves before editing activates');

// --- 覆盖层消费 restoreCaret（onAppear caretPosition） ---
check(overlay.includes('this.controller.caretPosition(Math.min(this.restoreCaret'),
  'overlay places caret at restoreCaret on appear');

// --- 链接命中优先于编辑激活（原有次序不变） ---
const ioet = canvas.slice(canvas.indexOf('private insideOverlayElementTap('),
  canvas.indexOf('private beginSelectionDragSession('));
check(ioet.indexOf('linkHitOnTextBlock') < ioet.indexOf('beginTextEditingAt'),
  'link hit precedes editing activation (unchanged tqa ordering)');

console.log(`D02_ORIGINAL_TAP_CARET_PLACE_OK TOTAL=${n} FAILED=0`);
