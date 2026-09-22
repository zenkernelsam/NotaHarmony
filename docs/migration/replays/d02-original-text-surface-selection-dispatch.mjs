// Phase 603 — TEXT 面（DEFAULT）选区手势分发 + 裸笔压制（dl1 z/elh.h）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   nti.java:467 — TEXT 面（m5f/a6f.L=TEXT）rz1.C(..., xtcVar2, true, false, …)
//     挂 dl1 case2；z=true（手写面 z=false）。
//   dl1.java:85-88 — z3 初值 true；z && !elh.h(...) → z3=false。
//   elh.java:249 — h() = (function0.invoke() && oqa.i==1) || (iqa.d & 66)!=0
//     = 手指触摸 或 手写笔桶键按下；裸笔（无桶键）→ false。
//   dl1.java:231-238（ftc 常态）/ 287-291（gtc）/ 337（itc）/ 382-386（null）—
//     覆盖层外 rtc/vtc 产出均受 z3 门控：z3=false（TEXT+裸笔）→ utc 落空。
//   dl1.java:212-227 — 覆盖层内 wtc/ttc/handle 不经 z3 门（任意输入生效）。
//   dl1.java:105-141 — deselectMode（ftc.h）stc/qtc 不经 z3 门。
// Harmony：ToolType.DEFAULT（= 原版 TEXT 面）pointer-down 在 tape/checkbox
//   之后插入 dl1 分发；SourceTool.Pen ≈ 裸笔（无桶键信息，fail-closed）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const canvas = readFileSync(CANVAS, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- DEFAULT 分支内的 dl1 分发块 ---
const defIdx = canvas.indexOf('this.viewModel.currentTool === ToolType.DEFAULT');
const def = canvas.slice(defIdx, defIdx + 5200);
check(def.includes('event.sourceTool === SourceTool.Pen'),
  'bare-stylus suppression gate present on the TEXT surface');
check(def.indexOf('stylusSuppress') <
  def.indexOf('this.pointInRect({ x: touch.x, y: touch.y }, this.selectionRect)'),
  'suppression flag computed before inside/outside split');
check(def.includes('this.selectionTool.getState().deselectMode') &&
  def.includes('this.deselectTargetIdsAt(canvasP)') &&
  def.includes('this.selectionTool.cancelDeselectMode()'),
  'deselectMode dispatch on TEXT surface (stc/qtc, not gated)');
check(def.indexOf('deselectMode') < def.indexOf('stylusSuppress') ||
  def.indexOf('this.selectionTool.getState().deselectMode') <
  def.indexOf('if (!stylusSuppress)'),
  'deselectMode dispatch precedes the suppression-gated branch');
check(def.includes('this.tryStartSelectionResize({ x: touch.x, y: touch.y })'),
  'corner/rotate handles active on TEXT surface inside-overlay');
check(def.includes('this.insideOverlayElementTap(selState, insideHitId, canvasP)'),
  'inside-overlay ttc dispatch on TEXT surface');
check(def.includes('this.beginSelectionDragSession(canvasP,'),
  'inside-overlay wtc whole-selection drag on TEXT surface');
check(def.indexOf('if (!stylusSuppress)') <
  def.indexOf('this.applyTapSelect(hitId)'),
  'outside-hit vtc gated by bare-stylus suppression');
check(def.indexOf('this.applyTapSelect(hitId)') <
  def.indexOf('this.clearSelectionWithRegisterReset()'),
  'outside: hit → vtc before miss → rtc');
check(def.indexOf('const now: number = Date.now()') >
  def.indexOf('this.clearSelectionWithRegisterReset()'),
  'suppressed/unclaimed taps fall through to the TEXT gesture surface');
check(def.includes('this.isInSelectionMenu(touch.x, touch.y)'),
  'selection menu region excluded before dispatch');

// --- 共享助手被三个调用点复用 ---
check((canvas.match(/this\.applyTapSelect\(/g) || []).length >= 3,
  'applyTapSelect shared by outside/idle/TEXT-surface tap-select');
check((canvas.match(/this\.beginSelectionDragSession\(/g) || []).length >= 3,
  'beginSelectionDragSession shared by wtc paths');
check((canvas.match(/this\.tryStartSelectionResize\(/g) || []).length >= 2,
  'tryStartSelectionResize shared by SELECTION and TEXT surfaces');
check((canvas.match(/this\.insideOverlayElementTap\(/g) || []).length >= 2,
  'insideOverlayElementTap shared by SELECTION and TEXT surfaces');

console.log(`D02_ORIGINAL_TEXT_SURFACE_DISPATCH_OK TOTAL=${n} FAILED=0`);
