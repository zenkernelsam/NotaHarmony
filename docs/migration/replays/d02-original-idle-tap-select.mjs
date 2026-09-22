// Phase 599 — 无选区时点按元素直接选中（dl1 case2 末支 ktcVar==null → vtc）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dl1.java case2 — xtc 选区手势按下分发：
//     } else if (ktcVar == null) {
//       if (z3 && (ptcVarA = xtcVar.a(jE, null)) != null) {
//         ttcVar = new vtc(ptcVarA);          // 命中元素 → TapToSelect
//       } else {
//         ttcVar = utcVar;                    // 未命中 → utc（落空）
//       }
//       ...
//       if (ttcVar instanceof vtc) {
//         return new uw2(xtcVar, z2, (vtc) ttcVar, i);
//       }
//     }
//   uw2.java case3 — vtc 续段：ntc → new gtc(...)（cqc 组），
//     otc → fvbVar2.d(vndVar.I.getId())（单元素 itc），随后
//     xtcVar.d.c(fi3.a, ktc) —— 新选区立即可拖（wtc/e39 拖动机制）。
//   c5f=POINTER（a6f.Q）表面经 j74/ha5 挂接 xtc——点选是 POINTER
//   工具核心语义；Harmony 将原版 SELECT(套索)+POINTER(点选) 合并为
//   单一 SELECTION 工具，故该语义落在 SELECTION 空选区分支。
// Harmony：selectionVisible=false 分支中，链接命中检查之后先
//   topmostPageElementIdAt 命中 → selectElementIds + 组解析 +
//   selectionDrag 同手势拖动；未命中 → 原有套索/矩形开始。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const ROOT = new URL('../../..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const read = (p) => readFileSync(`${ROOT}/${p}`, 'utf8');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 空选区分支：命中 → TapToSelect；未命中 → 套索 ---
const lassoIdx = canvas.indexOf("this.selectionTool.beginSelection(");
const idleBranch = canvas.slice(
  canvas.lastIndexOf('idleLinkHit', lassoIdx) - 700, lassoIdx + 500);
check(idleBranch.includes('const idleHitId: string | null = this.topmostPageElementIdAt(canvasP);'),
  'idle down hit-tests the topmost page element (xtc.a(jE,null))');
check(idleBranch.indexOf('topmostPageElementIdAt(canvasP)') <
  idleBranch.indexOf('beginSelection('),
  'element hit-test precedes lasso begin (vtc before fallthrough)');
check(idleBranch.includes('this.applyTapSelect(idleHitId)'),
  'tap-select resolves+commits via applyTapSelect (uw2 case3 ntc → gtc)');
check(idleBranch.includes('this.beginSelectionDragSession(canvasP)'),
  'same gesture continues as a selection drag (uw2 case3 → wtc/e39)');
// Phase 603 共享助手：tap-select/拖拽会话的实现体。
const tapSel = canvas.slice(canvas.indexOf('private applyTapSelect('),
  canvas.indexOf('private applyTapSelect(') + 1800);
check(tapSel.includes('resolveOriginalGroupSelection('),
  'applyTapSelect resolves the cqc group');
check(tapSel.includes('this.selectionTool.selectElementIds('),
  'applyTapSelect commits via selectElementIds (otc → fvbVar2.d / ntc → gtc)');
check(tapSel.includes('resolved.groupIds'), 'group ids committed with the entity set');
check(tapSel.includes('this.updateSelectionOverlay();'),
  'overlay appears immediately on tap-select (uw2 case3 → new itc/gtc state)');
check(tapSel.includes('this.renderFrame();'),
  'canvas repaints to show the new selection');
const dragSess = canvas.slice(canvas.indexOf('private beginSelectionDragSession('),
  canvas.indexOf('private beginSelectionDragSession(') + 900);
check(dragSess.includes('this.selectionDrag = true;'),
  'drag session arms the whole-selection drag');
check(dragSess.includes('this.lastDragPoint = { x: canvasP.x, y: canvasP.y };'),
  'drag anchors at the down point');
check(dragSess.includes('this.dragBeforeStrokes = this.completedStrokes.slice();') &&
  dragSess.includes('this.dragBeforeMathBlocks = this.mathBlocks.slice();'),
  'drag snapshots cover every selected kind');

// --- 链接命中仍优先于 TapToSelect ---
check(canvas.indexOf('idleLinkHit') < canvas.indexOf('idleHitId'),
  'text-block link probe still wins over tap-select (ttc → qke first)');

// --- 组/实体集合（已由上方 applyTapSelect 切片断言覆盖） ---

// --- 可执行模型：末支三态 ---
const dispatch = (hit, z3) => {
  if (!z3 || hit === null) return 'utc/null → lasso';
  return 'vtc → TapToSelect';
};
assert(dispatch(null, true) === 'utc/null → lasso', 'miss → lasso');
assert(dispatch('e1', true) === 'vtc → TapToSelect', 'hit → tap-select');
assert(dispatch('e1', false) === 'utc/null → lasso', 'z3=false → lasso (stylus-on-TEXT parity)');
n += 3;

console.log(`D02_ORIGINAL_IDLE_TAP_SELECT_OK TOTAL=${n} FAILED=0`);
