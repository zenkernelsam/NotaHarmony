// Phase 620 — 交互标记后 200ms 内抑制长按粘贴菜单（yqa/g39.b()）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   g39.java:17-30 — a()：d=now+u50 协程打点；b()：d+200>=now → true。
//   g1f.java:248-266 — ktc 事件 null/!i()（选区变空）→ Q.a() 打点；
//     默认分支 r5f 手势面事件 → N.a()+f0.a()+Q.a()（面切换全打点）。
//   yqa.java:215-223 — z=false 分支：if (g39Var.b()) return;——标记后
//     200ms 内的长按粘贴菜单分发被静默吞掉。
//   ej9.java:248-254 — case19 wtc：!g39.b() 才发射 e39——同一标记窗
//     也抑制拖拽结束通知（Harmony 无 l51 事件总线，该面不可表达，
//     记入 ADR 边界）。
// Harmony 对齐：clearSelectionWithRegisterReset（+两处直接 deselect）
//   记 lastSelectionClearTime；EditorViewModel.applyActiveState 在
//   currentTool 真正变化时记 toolChangedAt；长按粘贴菜单
//   ClipboardPasteContextMenu 经 recentInteractionGateActive()
//   （<200ms）门控——空 Menu 不弹层（bindContextMenu 无 veto）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);
const vm = read(VM);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 标记位：选区变空（g1f case4 等价） ---
check(view.includes('private lastSelectionClearTime: number = 0;'),
  'lastSelectionClearTime field present');
const clearIdx = view.indexOf('private clearSelectionWithRegisterReset(');
check(clearIdx > 0, 'clearSelectionWithRegisterReset present');
const clear = view.slice(clearIdx, clearIdx + 400);
check(clear.includes('this.lastSelectionClearTime = Date.now();') &&
  clear.indexOf('lastSelectionClearTime') < clear.indexOf('selectionTool.deselect()'),
  'clear funnel stamps the marker before deselect (g39.a parity)');
const marks = view.split('this.lastSelectionClearTime = Date.now();').length - 1;
check(marks === 3,
  `all three selection-emptied paths stamp the marker (got ${marks})`);

// --- 标记位：手势面切换（g1f 默认分支 r5f → Q.a() 等价） ---
check(vm.includes('toolChangedAt: number = 0;'), 'toolChangedAt field present');
const asIdx = vm.indexOf('private applyActiveState()');
check(asIdx > 0, 'applyActiveState present');
const as = vm.slice(asIdx, asIdx + 1800);
check(as.includes('const nextTool: ToolType') &&
  as.includes('if (nextTool !== this.currentTool)') &&
  as.includes('this.toolChangedAt = Date.now();') &&
  as.includes('this.currentTool = nextTool;'),
  'toolChangedAt stamped only when the surface tool actually changes');

// --- 门：yqa/g39.b() 等价 ---
const gateIdx = view.indexOf('private recentInteractionGateActive()');
check(gateIdx > 0, 'recentInteractionGateActive present');
const gate = view.slice(gateIdx, gateIdx + 500);
check(gate.includes('Math.max(this.lastSelectionClearTime,') &&
  gate.includes('this.viewModel.toolChangedAt)'),
  'gate reads both markers (selection-clear + tool-change)');
check(gate.includes('Date.now() - marked < 200'), '200ms window preserved (g39.b)');
check(gate.includes('marked !== 0'), 'unset markers do not gate');

// --- 门接菜单 ---
const menuIdx = view.indexOf('private ClipboardPasteContextMenu()');
check(menuIdx > 0, 'ClipboardPasteContextMenu present');
const menu = view.slice(menuIdx, menuIdx + 700);
check(menu.includes('if (!this.recentInteractionGateActive() &&'),
  'menu items suppressed inside the 200ms gate (empty Menu = no popup)');
check(menu.includes('this.canPasteClipboardNow()') &&
  menu.includes('this.canUseOriginalClipboardImage()'),
  'existing paste conditions preserved inside the gate');

console.log(`D02_ORIGINAL_RECENT_INTERACTION_MENU_GATE_OK TOTAL=${n} FAILED=0`);
