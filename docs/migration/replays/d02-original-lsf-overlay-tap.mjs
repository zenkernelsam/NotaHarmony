// Phase 1446 — 1.4.2 zf3 覆盖层内按下分发对齐（lsf 支补全 + e.c 移动会话）。
// Original evidence (decompiled_1.4.2/sources/defpackage):
//   zf3.java case1 lsf 支（~220-244）：lsf 选区无界内拖拽域——
//     dtfVar.a(jE,null) 命中分发：落空 → xsf → rv0(dtf,z2,5) →
//     dtfVar.a.a()+c.a() 清选；命中 rsf 组 → btf；命中 ssf 异元素 → btf；
//     命中同元素：vvh → zsf（z2 且编辑会话激活时压制为 atf），非 vvh → ctf。
//   zf3.java case1 isf 支（~155-190）：界内一律 ctf 拖拽（含 isf 单文本，
//     不产 zsf）；jsf 命中 vvh/非组成员 → ctf，非 vvh 组成员 → zsf。
//   ch1.java case8（btf）：hmb.g(new lsf/jsf) 重选 + 尾部
//     dtfVar.e.c(tap, msf) 起同手势移动会话（r3b 状态机，usf case0 同族）。
//   ch1.java case9（zsf）：dtf.d(new zyh(id)) 进文本编辑 +
//     w8d.d(zsf.b) 落 caret 于点按位。
//   rv0.java case5（xsf）：dtfVar.a.a() 清选区。
// Harmony：insideOverlayElementTap 重构为 lsf/ksf 两支——lsf 界内落空
//   清选、异命中重选+起移动会话、同文本块链接探/进编辑落 caret、同非
//   文本返回 false 走拖拽；isf/jsf 界内保持拖拽语义（isf 单文本不再
//   误入编辑）；选区外两处重选点补 beginSelectionDragSession。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

const helper = canvas.slice(canvas.indexOf('private insideOverlayElementTap('),
  canvas.indexOf('private beginSelectionDragSession('));

// --- lsf 判定：点选型单元素（!supportsDeselectMode，P1439 来源标记） ---
check(helper.includes('!selState.supportsDeselectMode') &&
  helper.includes('selState.selectedGroupIds.length === 0') &&
  helper.includes('selectedCount === 1'),
  'lsf gate: tap-sourced single element only (isf drawn single excluded)');

// --- lsf 界内落空 → xsf → rv0 清选 ---
const lsfBody = helper.slice(helper.indexOf('if (lsfLike)'));
check(lsfBody.indexOf('insideHitId === null') <
  lsfBody.indexOf('this.clearSelectionWithRegisterReset()') &&
  lsfBody.indexOf('this.clearSelectionWithRegisterReset()') <
  lsfBody.indexOf('insideHitId !== selectedId'),
  'lsf inside-bounds miss → xsf → rv0 clear selection');

// --- lsf 界内异命中 → btf → ch1 case8：重选 + e.c 移动会话 ---
check(lsfBody.includes('insideHitId !== selectedId'),
  'lsf different-element hit branch exists');
check(lsfBody.indexOf('this.applyTapSelect(insideHitId)') >
  lsfBody.indexOf('insideHitId !== selectedId') &&
  lsfBody.indexOf('this.applyTapSelect(insideHitId)') <
  lsfBody.indexOf('this.beginSelectionDragSession(canvasP, screenP)'),
  'lsf different-hit reselects (group-aware) then arms e.c move session');

// --- lsf 同文本块命中 → zsf：链接先行否则进编辑落 caret ---
check(lsfBody.includes('insideHitId === selState.selectedTextBlockIds[0]'),
  'lsf same-element text branch (zsf)');
const zsfPath = lsfBody.slice(lsfBody.indexOf('insideHitId === selState.selectedTextBlockIds[0]'),
  lsfBody.indexOf('insideHitId === selState.selectedTextBlockIds[0]') + 900);
check(zsfPath.indexOf('linkHitOnTextBlock') < zsfPath.indexOf('beginTextEditingAt'),
  'zsf: link probe precedes editing activation (uw2 case4 / qke)');
check(zsfPath.includes('this.beginTextEditingAt(canvasP)'),
  'zsf → ch1 case9: enter editing, caret at tap (w8d.d)');

// --- lsf 同非文本命中 → 返回 false 走 ctf 拖拽 ---
check(lsfBody.indexOf('insideHitId === selState.selectedTextBlockIds[0]') <
  lsfBody.lastIndexOf('return false;'),
  'lsf same non-text element falls through to ctf drag');

// --- isf 界内单文本不进编辑：编辑激活只在 lsfLike 块内 ---
check(helper.indexOf('this.beginTextEditingAt(canvasP)') >
  helper.indexOf('if (lsfLike)') &&
  helper.indexOf('this.beginTextEditingAt(canvasP)') <
  helper.indexOf('selState.selectedGroupIds.length > 0'),
  'isf single text inside-bounds taps drag (ctf), never enter editing');

// --- jsf 纯组命中非文本成员 → 消费不拖拽（保留 P603 语义） ---
const gtc = helper.slice(helper.indexOf('selState.selectedGroupIds.length > 0'));
check(gtc.includes('selectedTextBlockIds.indexOf(insideHitId) < 0') &&
  gtc.includes('leaves.indexOf(insideHitId) >= 0') &&
  gtc.includes('return true;'),
  'jsf non-vvh member hit consumed without drag (zsf → zyh non-text no-op)');

// --- 选区外重选点补 e.c 移动会话（ch1 case8 尾部）：两处 ---
const applySites = canvas.match(/this\.applyTapSelect\(hitId\);/g) || [];
check(applySites.length >= 2,
  'both outside-overlay reselect sites present (TEXT + SELECTION faces)');
let armed = 0;
for (const m of canvas.matchAll(
  /this\.applyTapSelect\(hitId\);[\s\S]{0,300}?this\.beginSelectionDragSession\(canvasP,/g)) {
  armed++;
}
check(armed >= 2,
  'outside-overlay reselect arms e.c move session on both faces');

// --- screenP 参数贯穿（lsf 异命中拖拽需要屏幕坐标） ---
check(canvas.includes('canvasP: Point2D, screenP: Point2D): boolean') &&
  (canvas.match(/insideOverlayElementTap\(selState, insideHitId, canvasP,/g) || [])
    .length === 2,
  'insideOverlayElementTap carries screenP at both call sites');

console.log(`D02_ORIGINAL_LSF_OVERLAY_TAP_OK TOTAL=${n} FAILED=0`);
