// Phase 611 — 选区拖拽 touch-slop 门控（ycj.e → is7.onTouchSlopReached）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   ycj.java:99 — 选择面手势检测器 ycj.e(bra, is7.onStartDrag,
//     is7.onTouchSlopReached, is7.onDragMove, vo2(收尾), is7.onResetDrag)：
//     awaitPointerSlopOrCancellation 族——位移未达 touch slop 前
//     onDragMove 不分发；slop 之内位移被检测器消费，仅超出部分入回调。
//   vo2 — 拖拽结束消费（套索/拖动提交）；未越 slop 的按下-抬起按点按走。
//   ha5.java:232 — 同族检测器亦驱动文本面（pn3.onTouchSlopReached）。
// Harmony 旧实现：selectionDrag/selectionResize 按下即生效，首个 move
//   增量直接 moveSelected/applySelectionResize——1px 抖动也会推动选区
//   并在抬起时提交变换。
// Harmony 新实现：selectionGestureSlopAdvance 累计屏幕位移 |Δ|，达 8px
//   （注册适配阈值，与点按判定半径同量级）方越阈；拖拽越阈首事件按
//   Compose 语义只应用超出部分 (|accum|-8)/zoom；未越阈的抬起分支
//   全部跳过——按-抬即点按，不产生变换/undo。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const read = (p) => readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
const view = read(VIEW);

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 状态与助手存在 ---
check(view.includes('selectionGestureSlopAccum'),
  'slop accumulator field present');
check(view.includes('selectionGestureSlopCrossed'),
  'slop-crossed flag present');
const advIdx = view.indexOf('private selectionGestureSlopAdvance(');
check(advIdx > 0, 'selectionGestureSlopAdvance helper exists');
const adv = view.slice(advIdx, advIdx + 1200);
check(adv.includes('Math.hypot(this.selectionGestureSlopAccum.x'),
  'accumulated screen displacement magnitude tested');
check(adv.includes('< 8'), '8px touch-slop threshold (registered adaptation)');
check(adv.indexOf('selectionGestureSlopCrossed = true') >
  adv.indexOf('< 8'), 'cross flag set only after threshold reached');
check(adv.includes('selectionGestureSlopCrossed') && adv.indexOf('return true') > 0,
  'already-crossed events pass through (post-slop onDragMove)');

// --- 会话初始化：拖拽与缩放会话都重置 slop 状态 ---
const sessIdx = view.indexOf('private beginSelectionDragSession(');
check(sessIdx > 0, 'beginSelectionDragSession present');
const sess = view.slice(sessIdx, sessIdx + 900);
check(sess.includes('screenP: Point2D'),
  'drag session takes the screen-space press point');
check(sess.includes('selectionGestureSlopCrossed = false'),
  'drag session resets slop state');
const rsIdx = view.indexOf('private tryStartSelectionResize(');
check(rsIdx > 0, 'tryStartSelectionResize present');
const rs = view.slice(rsIdx, rsIdx + 2200);
check(rs.includes('selectionGestureSlopCrossed = false'),
  'resize session resets slop state');
check(rs.includes('selectionGestureLastScreen = { x: screenP.x'),
  'resize session seeds the screen-space anchor');

// --- move 分支：resize/drag 都被 slop 门控 ---
const rsMove = view.slice(view.indexOf('if (this.selectionResize) {'),
  view.indexOf('if (this.selectionDrag) {'));
check(rsMove.includes('selectionGestureSlopAdvance'),
  'resize moves gated by slop advance');
check(rsMove.indexOf('selectionGestureSlopAdvance') <
  rsMove.indexOf('applySelectionResize'),
  'resize applies only after slop crossed');
const dragMoveIdx = view.indexOf('if (this.selectionDrag) {');
const dragMove = view.slice(dragMoveIdx, dragMoveIdx + 2400);
check(dragMove.includes('selectionGestureSlopAdvance'),
  'drag moves gated by slop advance');
check(dragMove.indexOf('selectionGestureSlopAdvance') <
  dragMove.indexOf('moveSelected'),
  'drag applies moveSelected only after slop crossed');
check(dragMove.includes('wasCrossed') && dragMove.includes('dist - 8'),
  'first post-slop event applies only the residual beyond the threshold');
check(dragMove.includes('/ zoom'),
  'residual converts screen px to canvas units via zoom');

// --- 抬起分支：未越阈不应用最终增量 ---
const upIdx = view.indexOf('} else if (this.selectionResize) {');
const up = view.slice(upIdx, upIdx + 1600);
check(up.includes('if (this.selectionGestureSlopCrossed)'),
  'up-path resize gated on slop-crossed');
check(up.indexOf('selectionGestureSlopCrossed') < up.indexOf('applySelectionResize'),
  'no final resize when slop never crossed');
const upDrag = up.slice(up.indexOf('} else if (this.selectionDrag) {'));
check(upDrag.includes('if (this.selectionGestureSlopCrossed)'),
  'up-path drag gated on slop-crossed (tap = no transform commit)');

// --- 会话清理：提交与取消路径都复位 ---
const resets = view.split('selectionGestureSlopCrossed = false').length - 1;
check(resets >= 4, 'slop state reset at session begin + commit + cancel paths');

console.log('D02_ORIGINAL_DRAG_TOUCH_SLOP_OK TOTAL=' + n + ' FAILED=0');
