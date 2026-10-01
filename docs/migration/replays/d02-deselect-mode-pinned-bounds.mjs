// Phase 1445 — deselectMode 钉住界 + 点除语义精证（mud case7 / zf3 / m5b 13-14）
// 原版证据（decompiled_1.4.2）：
//   zf3.java:106-152 — deselectMode 点按分发（仅 isfVar.h 时产事件）：
//     ssf 命中且 ∈g → ysf({id},null)；rsf 组命中（tof.b∩g≠∅）→
//     ysf(tof.b,tof.a)=整组叶子+组 token；界内空点 → atf(None)；
//     界外 → wsf(CancelDeselectMode)。界内判定=f5n.h(isfVar.a,…)→
//     命中域=入模时的 a（点除不改）。
//   mud.java case7 — 点除变换：g′=y2g.d0(g,set6)、i′=y2g.f0(i,set6)、
//     m′=n′=m−{tof.a==t87Var2}；a/b/c/j 全部保留（掩码3775只覆写
//     g/i/m/n）→ 选区轮廓 o=hsm.b(a,f,m) 在模式下钉住不收缩；
//     g′ 全空 → return null → 选区消亡。
//   d9c.java:255 — mud 返 null → omeVar.m=null（快照弃置，不可再取消）。
//   dqd.java case16/17 — 进模式 h=true / 出模式 h=false+i=∅（均保 g）。
//   m5b.java case13 = onConfirmDeselectMode：ome.m=null + dqd(17)
//     变换当前 isf → 缩减成员保持；case14 = onCancelDeselectMode：
//     htd(快照,5) 回灌——仅当流内仍是同一 isf（j=UUID 不变）且仍 h
//     才恢复，否则保持现状不覆写。
// Harmony：SelectionState.deselectBounds = 入模界（钉住）；
//   deselectElements 加 h 门 + deselectBounds 三出口清零；overlay
//   尾段 deselectMode 用钉住界替代成员 union。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');

const tool = read('note/src/main/ets/rendering/SelectionTool.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 1) deselectBounds 状态字段 + 注释登记 mud/zf3 证据 ---
check(tool.includes('deselectBounds: Rect2D | null'),
  'SelectionState.deselectBounds（isf.a 钉住界）');
check(tool.includes('mud case7') && tool.includes('o=a'),
  '钉住界注释引 mud case7 / o=a∪m 证据');

// --- 2) enterDeselectMode 接收入模界并存入状态 ---
check(/enterDeselectMode\(bounds: Rect2D \| null = null\)/.test(tool),
  'enterDeselectMode 签名接入模界');
const enter = tool.slice(tool.indexOf('enterDeselectMode(bounds'),
  tool.indexOf('enterDeselectMode(bounds') + 1200);
check(enter.includes('this.state.deselectMode = true') &&
  enter.includes('this.state.deselectBounds = bounds'),
  '入模置 deselectMode + 钉住界（mud 不改 a → 轮廓固定）');

// --- 3) deselectElements：h 门 + g/i/m 语义 ---
const deselectEls = tool.slice(tool.indexOf('deselectElements(entityIds'),
  tool.indexOf('deselectElements(entityIds') + 1400);
check(deselectEls.includes('if (!this.state.deselectMode)'),
  '非 deselectMode 调用拒（zf3 仅 h=true 产 ysf）');
check(deselectEls.includes('filter(keep)') && deselectEls.includes('deselected.add(id)') &&
  deselectEls.includes('this.deselect()'),
  'g′=g−set6、i′=i∪set6、全空→deselect()（mud case7 + g.isEmpty→null）');
check(!deselectEls.includes('deselectBounds ='),
  '点除不改钉住界（mud 掩码3775 不覆写 a/b/c）');

// --- 4) confirm/cancel/deselect 三出口清钉住界 ---
const confirm = tool.slice(tool.indexOf('confirmDeselectMode(): void'),
  tool.indexOf('confirmDeselectMode(): void') + 400);
check(confirm.includes('deselectBounds = null'),
  'confirmDeselectMode 清钉住界（dqd case17 出模式）');
const cancel = tool.slice(tool.indexOf('cancelDeselectMode(): void'),
  tool.indexOf('cancelDeselectMode(): void') + 1100);
check(cancel.includes('deselectBounds = null') &&
  cancel.includes('snapshot.selectedGroupIds'),
  'cancelDeselectMode 恢复快照 + 清钉住界（m5b case14→htd case5）');
const deselect = tool.slice(tool.indexOf('deselect(): void'),
  tool.indexOf('deselect(): void') + 900);
check(deselect.includes('deselectBounds = null') &&
  deselect.includes('preDeselectSelection = null'),
  'deselect() 清钉住界 + 弃快照（d9c mud→null → ome.m=null）');

// --- 5) 其它复位路径清钉住界（beginSelection/selectElementIds） ---
const begin = tool.slice(tool.indexOf('beginSelection(mode'),
  tool.indexOf('beginSelection(mode') + 1400);
check(begin.includes('deselectBounds = null'), 'beginSelection 复位钉住界');
const selIds = tool.slice(tool.indexOf('selectElementIds(strokeIds'),
  tool.indexOf('selectElementIds(strokeIds') + 1400);
check(selIds.includes('deselectBounds = null'), 'selectElementIds 复位钉住界');

// --- 6) 画布侧：入模传当前界 + overlay 钉住界覆盖 ---
check(canvas.includes('enterDeselectMode(this.selectionBoundsCanvas())'),
  'DESELECT 动作以当前选区界入模（a=o 入模瞬时值）');
const overlayTail = canvas.slice(canvas.indexOf('private updateSelectionOverlay()'));
check(/state\.deselectMode && state\.deselectBounds !== null[\s\S]{0,400}rect = \{/.test(overlayTail),
  'updateSelectionOverlay：deselectMode 下用钉住界替代成员 union');

console.log(`PHASE1445_DESELECT_PINNED_BOUNDS_OK TOTAL=${total} FAILED=0`);
