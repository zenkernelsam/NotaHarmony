// Phase 618 — DUPLICATE 粘贴位置带 10% 宽（≤30）偏移（cg2.a()）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   lg2.java:171-191 — b()（DUPLICATE 协程）：粘贴位置 =
//     ei3.a(fE2+fE, f(jC)+f2) = cg2.c() + cg2.a() 分量相加。
//   cg2.java:21-26 — a()：fMin = min((cmb.c-cmb.a)*0.1f, 30f)，
//     打包 (fMin,fMin)——选区矩形宽度的 10%、上限 30 的等量
//     x/y 偏移向量；c() = fi3.b(cmb) = 矩形中心。
//   fi3.java:34-38 — b(cmb) = ((a+c)/2, (b+d)/2) = 中心。
//   即原版 DUPLICATE 副本相对原选区向右下错开
//   min(选区宽*0.1, 30) 页面单位；常规 PASTE 不走 cg2.a()，
//   无此偏移（Harmony selectionPasteTarget 供两者共用，
//   偏移仅注入 duplicateSelected）。
// Harmony 对齐：duplicateSelected 计算 rectWidthCanvas =
//   (selectionRect.right-left)/zoom（屏幕像素→页面单位），
//   nudge = min(width*0.1, 30)，粘贴中心 = target+nudge。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

const dupIdx = view.indexOf('private duplicateSelected(');
check(dupIdx > 0, 'duplicateSelected present');
const dup = view.slice(dupIdx, dupIdx + 1600);

// --- 偏移计算（cg2.a() 等价） ---
check(dup.includes('rectWidthCanvas') &&
  dup.includes('selectionRect.right - this.selectionRect.left'),
  'duplicate nudge derives from selection-rect width');
check(dup.includes('/ this.viewport.zoom'),
  'screen px -> page units conversion via zoom');
check(dup.includes('rectWidthCanvas * 0.1') && dup.includes('Math.min'),
  'offset = min(10% of width, 30) — cg2.a() parity');
check(dup.includes(', 30'), '30-unit cap preserved');

// --- 粘贴目标 = 中心 + 偏移 ---
check(dup.includes('const duplicateTarget: Point2D = { x: target.x + nudge, y: target.y + nudge }'),
  'duplicate pastes at center + nudge on both axes');
check(dup.includes('this.pasteClipboard(duplicateTarget)'),
  'pasteClipboard receives the nudged target');
check(!dup.includes('this.pasteClipboard(target);'),
  'unnudged center no longer used for duplicate');

// --- PASTE 路径不受偏移影响 ---
const pasteIdx = view.indexOf('action === SelectionMenuAction.PASTE');
check(pasteIdx > 0, 'PASTE dispatch present');
const pasteCtx = view.slice(pasteIdx, pasteIdx + 300);
check(pasteCtx.includes('this.pasteClipboard(target)') &&
  !pasteCtx.includes('nudge'),
  'menu PASTE keeps the un-nudged selectionPasteTarget');

// --- selectionPasteTarget 本身仍返回纯中心 ---
const targetIdx = view.indexOf('private selectionPasteTarget(');
check(targetIdx > 0, 'selectionPasteTarget present');
const tgt = view.slice(targetIdx, targetIdx + 1400);
check(tgt.includes('(this.selectionRect.left + this.selectionRect.right) / 2') &&
  !tgt.includes('nudge'),
  'selectionPasteTarget returns the plain rect center (offset lives in duplicateSelected)');

console.log(`D02_ORIGINAL_DUPLICATE_OFFSET_OK TOTAL=${n} FAILED=0`);
