// Phase 605 — LOCK/UNLOCK 对单元素选区无条件清选（dhb case18/19 itc 分支）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dhb.java:18001-18034 — itc 分支：命中实体 instanceof oy0（hp5 图片 /
//     xhe 文本 / r08 数学块）→ u5j.n(!t())；m4d+cih（n5d 形状）→
//     u5j.x(!t())；其余（如笔画）objX=null。随后无条件
//     xj2.A(wsc) + fvbVar.a()——即使无可锁切换也清选。
//   dhb.java:18015-18034 — 多选分支：boolK=xsc.k(ktc) 仅统计形状
//     （非 m4d 立即 return null）；vz6 只翻转 t()!=!allLocked 的形状；
//     fvb.a() 仅在 arrayList9 非空（确有翻转）时执行。
//   n5d.java:214-216 — t() = positionLockedRegister。
//   xsc.java:216-243 — k(ktc)：遍历 h()，非 m4d 即 null；cih.a 形状
//     统计"是否全部 positionLocked"。
// Harmony：setSelectedPositionLocked 空 diff 早退时补 itc 语义——
//   单元素选区（含笔画等不可锁定类）仍 clearSelectionWithRegisterReset；
//   多选空 diff（全形状已在目标态）保留选区。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const canvas = readFileSync(CANVAS, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- setSelectedPositionLocked：空 diff 的 itc 清选 ---
const fn = canvas.slice(canvas.indexOf('private setSelectedPositionLocked('),
  canvas.indexOf('private setSelectedPositionLocked(') + 5200);
const emptyIdx = fn.indexOf('afterImages.length === 0 && afterMathBlocks.length === 0');
check(emptyIdx > 0, 'empty-diff early return present');
const emptyBlock = fn.slice(emptyIdx, emptyIdx + 900);
check(emptyBlock.includes('state.selectedGroupIds.length === 0'),
  'itc clear excludes group selections (itc has no groups)');
check(emptyBlock.includes('selectedMathIds.length === 1'),
  'single-element selection detected across all five kinds');
check(emptyBlock.includes('this.clearSelectionWithRegisterReset()'),
  'single-element empty-diff still clears (fvb.a() unconditional)');
check(fn.indexOf('clearSelectionWithRegisterReset', emptyIdx + 900) > 0,
  'applied-diff path keeps the existing unconditional clear');

// --- 多选空 diff 保留选区：单元素条件不命中即直接 return ---
check(emptyBlock.indexOf('return;') > emptyBlock.indexOf('clearSelectionWithRegisterReset'),
  'multi-element empty-diff falls through to return (arrayList9.isEmpty parity)');

// --- 目标态语义：z15=!allLocked，仅翻转未达标的元素 ---
check(fn.includes('(shape.positionLocked === true) === locked'),
  'shapes already at the target state are skipped (t()!=z15 filter)');
check(fn.includes('text.positionLocked === true) === locked') &&
  fn.includes('image.positionLocked === locked') &&
  fn.includes('math.positionLocked === locked'),
  'text/image/math skip-if-at-target for the single-element path');

console.log(`D02_ORIGINAL_LOCK_CLEARS_NOOP_SINGLE_OK TOTAL=${n} FAILED=0`);
