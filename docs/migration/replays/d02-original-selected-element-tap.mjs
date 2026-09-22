// Phase 593 — 覆盖层内元素级 ttc 产出（itc/gtc 分支）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dl1.java:265-281（itc 单元素选区）— 覆盖层内按下，xtc.c.e 命中
//     最上层元素：命中 id == itc.a（同一选中元素）且 ly3 instanceof
//     xhe（cie = 文本块实体）→ ttc；否则 wtc 拖拽。
//   dl1.java:213-227（gtc 组选区）— 覆盖层内按下：命中元素为文本块或
//     不在 gtc.b（组成员集）→ wtc 拖整组；命中非文本成员 → ttc。
//   uw2.java case4 — ttc → xtcVar.d(new qke(id)) + 活动文本块链接探测。
//   uke.java:258-268 — qke → ukeVar.p.get(qo5)：激活文本块编辑器（ake）。
//   cie.java — xhe 唯一实现：paper/resizesWidthToFitText 寄存器 = 文本块。
//   ftc 分支 — 覆盖层内按下无条件 wtc（多元素选区恒拖拽）。
// Harmony：覆盖层内按下先判元素级 ttc——单文本块选区命中同块 →
//   链接探测（命中→链接菜单）否则 beginTextEditingAt（qke 激活等价）；
//   纯组选区命中非文本成员 → 消费不拖拽；其余 → 整体拖拽。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const canvas = readFileSync(CANVAS, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 覆盖层内按下 → itc/gtc ttc 分流（先于 selectionDrag） ---
const branch = canvas.slice(canvas.indexOf('isSelectionActive()'),
  canvas.indexOf('isSelectionActive()') + 7600);
check(branch.includes('topmostPageElementIdAt(canvasP)'),
  'inside-press probes the topmost element (xtc.c.e)');
check(branch.indexOf('topmostPageElementIdAt(canvasP)') <
  branch.indexOf('this.selectionDrag = true'),
  'element-level dispatch precedes the whole-selection drag');

// --- itc：单文本块选区命中同块 → ttc（链接探测 → qke 激活编辑） ---
check(branch.includes('selectedTextBlockIds.length === 1') &&
  branch.includes('selectedStrokeIds.length === 0') &&
  branch.includes('selectedGroupIds.length === 0'),
  'itc guard: exactly one selected text block, nothing else');
check(branch.includes('insideHitId === selState.selectedTextBlockIds[0]'),
  'itc requires the tap on the same selected element (itcVar.a)');
const itcPath = branch.slice(branch.indexOf('insideHitId === selState.selectedTextBlockIds[0]'),
  branch.indexOf('insideHitId === selState.selectedTextBlockIds[0]') + 700);
check(itcPath.includes('this.linkHitOnTextBlock(insideHitId, canvasP)') &&
  itcPath.includes('this.showTextBlockLinkMenu(linkHit)'),
  'itc text tap probes links first (uw2 case4 link check)');
check(itcPath.includes('this.beginTextEditingAt(canvasP)'),
  'itc text tap activates text editing (qke → uke ake parity)');

// --- gtc：纯组选区命中非文本成员 → ttc（qke 非文本 no-op，消费不拖拽） ---
const gtc = branch.slice(branch.indexOf('selState.selectedGroupIds.length > 0'),
  branch.indexOf('selState.selectedGroupIds.length > 0') + 900);
check(gtc.includes('selectedTextBlockIds.indexOf(insideHitId) < 0'),
  'gtc member tap excludes text blocks (xhe → wtc)');
check(gtc.includes('resolveOriginalSelectedGroupLeaves(') &&
  gtc.includes('leaves.length === selected.size') &&
  gtc.includes('leaves.indexOf(insideHitId) >= 0'),
  'gtc requires a pure group selection and a member hit (gtc.b)');
check(gtc.includes('this.isDrawing = true;') && gtc.includes('return;'),
  'gtc member tap consumes the gesture without dragging (qke non-text no-op)');

// --- 其余路径不变：ftc/多元素/未命中成员 → 整体拖拽 ---
check(branch.includes('this.selectionDrag = true') &&
  branch.includes('this.dragBeforeStrokes'),
  'wtc whole-selection drag remains the fallback');

console.log(`D02_ORIGINAL_SELECTED_ELEMENT_TAP_OK TOTAL=${n} FAILED=0`);
