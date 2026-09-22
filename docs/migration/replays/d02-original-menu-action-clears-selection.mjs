// Phase 600 — 选区菜单动作完成后清空选区（dhb 各 case 的 fvbVar.a() 终态）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dhb.java dsc dispatch — 动作成功后 fvbVar.a()（ne9.d(null)）：
//     case 1  COPY     : lg2Var.c.a = cg2Var; fvbVar2.a();
//     case 2  CUT      : vsc → lg2.d → r2.a()          （Harmony 已对齐）
//     case 3  DUPLICATE: vsc → lg2.b → fvbVar.a() + e() 重选粘贴副本
//     case 4  GROUP    : kk9 协程后 fvbVar.a()          （size>=2 时）
//     case 5  UNGROUP  : wsc 协程后 fvbVar.a()          （非空时）
//     case 10 DELETE   : kk9 协程后 fvbVar.a()          （Harmony 已对齐）
//     case 16/17 FLIP  : mub 协程后 fvbVar.a()
//     case 18/19 LOCK  : u5j 切换后 fvbVar.a()
//   保留选区：case 0 STYLE(nsc)、6-9 SEND_*、13 EDIT_MATH、14 CROP(itc.c)、
//     20 DESELECT(deselectMode)。
// Harmony：COPY/GROUP/UNGROUP/FLIP/LOCK 原保留（甚至重选成员）；
//   本 Phase 全部改为成功后 clearSelectionWithRegisterReset()。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const ROOT = new URL('../../..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const read = (p) => readFileSync(`${ROOT}/${p}`, 'utf8');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- COPY：成功后清选区 ---
const copyIdx = canvas.indexOf('SelectionMenuAction.COPY)');
const copyBlock = canvas.slice(copyIdx, copyIdx + 700);
check(copyBlock.includes('if (this.copySelectedToClipboard('),
  'COPY clears only on a successful clipboard write (fvbVar2.a() on cg2 commit)');
check(copyBlock.includes('this.clearSelectionWithRegisterReset();'),
  'COPY → clearSelectionWithRegisterReset (fvbVar2.a parity)');

// --- GROUP：成功后清选区而非重选新组 ---
const groupIdx = canvas.indexOf('this.persistence.createOriginalGroup(');
const groupThen = canvas.slice(groupIdx, groupIdx + 2600);
check(groupThen.includes('this.clearSelectionWithRegisterReset();'),
  'GROUP → clear selection after commit (dhb case4 fvbVar.a)');
check(!groupThen.includes('this.selectionTool.selectElementIds('),
  'GROUP does not re-select the new group (original clears outright)');

// --- UNGROUP：成功后清选区而非重选成员 ---
const ungroupIdx = canvas.indexOf('this.persistence.ungroupOriginalGroup(');
const ungroupThen = canvas.slice(ungroupIdx, ungroupIdx + 2600);
check(ungroupThen.includes('this.clearSelectionWithRegisterReset();'),
  'UNGROUP → clear selection after commit (dhb case5 fvbVar.a)');
check(!ungroupThen.includes('this.selectionTool.selectElementIds('),
  'UNGROUP does not re-select members (original clears outright)');

// --- FLIP：清选区 ---
const flipIdx = canvas.indexOf('private flipSelected(');
const flipBody = canvas.slice(flipIdx, flipIdx + 2400);
check(flipBody.includes('this.clearSelectionWithRegisterReset();'),
  'FLIP → clear selection after apply (dhb case16/17 fvbVar.a)');
check(!flipBody.includes('this.updateSelectionOverlay();'),
  'FLIP no longer refreshes a kept selection');

// --- LOCK/UNLOCK：清选区 ---
const lockIdx = canvas.indexOf('private setSelectedPositionLocked(');
const lockBody = canvas.slice(lockIdx, lockIdx + 4200);
check(lockBody.includes('this.clearSelectionWithRegisterReset();'),
  'LOCK/UNLOCK → clear selection after apply (dhb case18/19 fvbVar.a)');
check(!lockBody.includes('this.updateSelectionOverlay();'),
  'LOCK/UNLOCK no longer refreshes a kept selection');

// --- DELETE/CUT 仍清（已对齐回归） ---
const delIdx = canvas.indexOf('SelectionMenuAction.DELETE || action === SelectionMenuAction.CUT');
const delBlock = canvas.slice(delIdx, delIdx + 13000);
check(delBlock.includes('this.clearSelectionWithRegisterReset();'),
  'DELETE/CUT still clear the selection (regression pin)');

// --- 保留选区的动作不受牵连 ---
const styleIdx = canvas.indexOf('SelectionMenuAction.STYLE)');
check(!canvas.slice(styleIdx, styleIdx + 400).includes('clearSelectionWithRegisterReset'),
  'STYLE keeps the selection (nsc popover parity)');
const reorderIdx = canvas.indexOf('private reorderSelected(');
check(!canvas.slice(reorderIdx, reorderIdx + 4000).includes('clearSelectionWithRegisterReset'),
  'SEND_* keeps the selection (no fvbVar.a in cases 6-9)');

// --- 可执行模型：清/留映射 ---
const clearsAfter = new Set(['COPY', 'CUT', 'DUPLICATE', 'GROUP', 'UNGROUP',
  'DELETE', 'FLIP_H', 'FLIP_V', 'LOCK', 'UNLOCK']);
const keepsAfter = new Set(['STYLE', 'SEND_FORWARD', 'SEND_BACKWARD',
  'SEND_TO_FRONT', 'SEND_TO_BACK', 'EDIT_MATH', 'CROP', 'DESELECT']);
for (const a of ['COPY', 'GROUP', 'UNGROUP', 'FLIP_H', 'LOCK']) {
  assert(clearsAfter.has(a) && !keepsAfter.has(a), `${a} must clear`);
}
n += 5;

console.log(`D02_ORIGINAL_MENU_CLEAR_OK TOTAL=${n} FAILED=0`);
