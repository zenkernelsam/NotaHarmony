// Phase 1469 — 1.4.2 Delete/Forward Delete 键盘删除选区（f2 兜底链 →
// go(bd8,msf) 协程）。
// Original evidence (decompiled_1.4.2):
//   f2.java:40-60 — pa8.O = ofk.e(67) = KEYCODE_DEL；
//     pa8.P = ofk.e(112) = KEYCODE_FORWARD_DEL。
//   f2.java:247-253 — !pa8.W(279) 块内、!rsi 门内的兜底链：
//     `pa8.a(n, P) || pa8.a(n, O)` —— 无修饰键门（Ctrl+Del 同删）；
//     `!lxm.a(o,1) || msf==null` → b2=0 不消费透传；
//     UP+选区非空 → tee.I(z(), go((byte)14, bd8, msf))。
//   go.java invokeSuspend case14（--comments-level debug 转储 L28a）：
//     wib.a.i0() 取 w0g → e52.i4(msf.h()) → q9l.a(ids, em4.F×3)
//     → oag.x2 → fq9.c0(w0g, elements, ofj, fm4.F) 批量删除
//     → ome.a() 清选（m=null + a.g(null)）。
//   sqf.java case10 —— 选区菜单 wqf.P(DELETE, ordinal10)：
//     p2d(urf, msf.h()) → urf.E(listX3) 内部同样
//     wib.a.i0 + fq9.c0 + urf.H.a() 清选 —— 与键盘支同核。
//   msf.h() 各实现（isf.g / ksf / lsf / jsf.b / hsf=空集）= 原始
//     选中 id 集——分发层不滤锁定元素（过滤在 fq9.d0 内部或不含）。
// Harmony：onCanvasKeyEvent !textEditing 块内增 DEL/FORWARD_DEL 支，
//   复用 SelectionMenuAction.DELETE 管线（删除+undo+persist+清选）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const CHORDS = 'note/src/main/ets/data/OriginalKeyboardChords.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const chords = readFileSync(CHORDS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量：DEL / FORWARD_DEL 键码 ---
check(chords.includes('ORIGIN_KEYCODE_DEL: number = 2055') &&
  chords.includes('ORIGIN_KEYCODE_FORWARD_DEL: number = 2071'),
  'Harmony keycodes 2055/2071 pinned (pa8.O=67 DEL / pa8.P=112 FORWARD_DEL)');
check(chords.includes('pa8.O = ofk.e(67)') && chords.includes('pa8.P = ofk.e(112)'),
  'constants carry original ofk.e evidence comment');

// --- 分发支：键码匹配 + UP+选区门 + DELETE 管线复用 ---
const delAnchor = 'pa8.O(67=DEL)/pa8.P(112=FORWARD_DEL)';
const delStart = canvas.indexOf(delAnchor);
check(delStart > 0, 'dispatch branch annotated with f2 pa8.O/P evidence');
const delBlock = canvas.slice(delStart, delStart + 900);
check(delBlock.includes('event.keyCode === ORIGIN_KEYCODE_DEL') &&
  delBlock.includes('event.keyCode === ORIGIN_KEYCODE_FORWARD_DEL'),
  'DEL and FORWARD_DEL both intercepted (pa8.a(n,P) || pa8.a(n,O))');
check(delBlock.includes('!isUp || !this.selectionTool.getState().isActive') &&
  delBlock.includes('return false'),
  'DOWN or no-selection → not consumed (f2 b2=0 fall-through)');
check(delBlock.includes('this.onSelectionMenuAction(SelectionMenuAction.DELETE)') &&
  delBlock.includes('return true'),
  'UP+selection → menu DELETE pipeline (go case14 = urf.E = fq9.c0 same core)');
// 无修饰键门：分支条件里不得出现 ctrl/shift/alt 判定。
const delCond = delBlock.slice(delBlock.indexOf('if (event.keyCode'),
  delBlock.indexOf('if (event.keyCode') + 200);
check(!delCond.includes('ctrl') && !delCond.includes('shift') &&
  !delCond.includes('keyChordAlt'),
  'no modifier gate on delete key (f2 分支无 db8.r/s 检查)');

// --- 位置：在 !textEditing 块内（!rsi 门）、DPAD nudge 支之后 ---
const nudgeIdx = canvas.indexOf('bd8.j0={pa8.e..h}');
check(nudgeIdx > 0 && delStart > nudgeIdx,
  'delete branch follows DPAD nudge in fallback chain order');
const textEditGate = canvas.indexOf('if (!this.textEditing) {');
check(textEditGate > 0 && textEditGate < delStart,
  'delete branch inside !textEditing block (Q.m instanceof rsi gate)');
const delBlockEnd = canvas.indexOf('}\n\n    // qa8(111,14)');
check(delBlockEnd > delStart,
  'delete branch still inside !textEditing before ESC dismiss');

// --- 删除管线等价性 pin：菜单 DELETE 支仍是统一出口 ---
const delAction = canvas.slice(canvas.indexOf('action === SelectionMenuAction.DELETE ||'),
  canvas.indexOf('action === SelectionMenuAction.DELETE ||') + 400);
check(delAction.includes('SelectionMenuAction.CUT'),
  'DELETE|CUT shared removal path (f2 go14 ↔ sqf case10 urf.E)');
check(canvas.includes('this.selectionTool.deleteSelected();') &&
  canvas.includes('this.clearSelectionWithRegisterReset();'),
  'delete clears selection (ome.a() = m=null + a.g(null))');
check(canvas.includes('UndoableActionType.DELETE_ELEMENTS') ||
  canvas.includes('UndoableActionType.DELETE_STROKE'),
  'undo transaction created (fq9.d0 批处理删除入历史)');

// --- 可执行模型：f2 分支门控语义 ---
function deleteKey(consumedBefore, action, selectionActive) {
  // lxm.a(o,1)=UP 门 + msf!=null 门；否则 b2=0 不消费
  if (consumedBefore) return 'earlier-branch';
  if (action !== 'UP' || !selectionActive) return 'pass-through';
  return 'deleted';
}
check(deleteKey(false, 'UP', true) === 'deleted',
  'model: UP + selection → delete');
check(deleteKey(false, 'UP', false) === 'pass-through',
  'model: UP + no selection → b2=0 pass-through');
check(deleteKey(false, 'DOWN', true) === 'pass-through',
  'model: DOWN → b2=0 pass-through even with selection');
check(deleteKey(true, 'UP', true) === 'earlier-branch',
  'model: earlier chain match consumes before delete branch');

console.log(`d02-original-selection-delete-key: ${n} checks OK`);
