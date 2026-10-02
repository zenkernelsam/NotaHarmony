// Phase 1467 — 1.4.2 ms1:667-683 旋转柄命中域 = 茎锚点条带矩形。
// Original evidence (decompiled_1.4.2/sources/defpackage/ms1.java:664-683):
//   触点 down 分发时，旋转柄命中域不是端点圆，而是 sbe(锚点±f5/f6,
//   ±(f21+f4)) 的条带矩形：锚点 = gsf.i(sbe,dir) 右（RTL 左）边中点，
//   LTR 条带 [锚x, 锚x+104/zoom] × [锚y−48/zoom, 锚y+48/zoom]，
//   RTL 镜像 [锚x−104/zoom, 锚x]，再经 f5n.h 绕枢轴反旋入未旋转选区系
//   判定。104 = 茎 56 + 端点 Ø32 半径 16 + 过冲 32（即 72+32），
//   48 = 端点半径 16 + 过冲 32（即 16+32）。
// Harmony：selectionRotateHandleAt 由端点 Ø44vp 圆改为等效条带矩形
//   （触点先 unrotateChromePoint 反旋入壳系，再测方向性矩形）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const LAYOUT = 'note/src/main/ets/ui/components/SelectionOverlayLayout.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const layout = readFileSync(LAYOUT, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量：条带触及/半高 ---
check(layout.includes('SELECTION_ROTATE_HANDLE_HIT_REACH: number = 104'),
  'hit reach = (72+32)/zoom → 屏 104vp（ms1 f5+f6 触及）');
check(layout.includes('SELECTION_ROTATE_HANDLE_HIT_HALF_H: number = 48'),
  'hit half-height = (16+32)/zoom → 屏 ±48vp（ms1 f21+f4）');

// --- 命中实现：壳系反旋 + 方向性矩形 ---
const hit = canvas.slice(canvas.indexOf('private selectionRotateHandleAt('),
  canvas.indexOf('private selectionRotateHandleAt(') + 1400);
check(hit.includes('this.selectionChromeGeom()'),
  'hit base = unrotated shell rect (selectionChromeGeom)');
check(hit.includes('this.unrotateChromePoint(p, g)'),
  'screen touch unrotated into shell frame (f5n.h inverse-rotate path)');
check(hit.includes('this.selectionRotateHandleRtl') &&
  hit.includes('? g.rect.left : g.rect.right'),
  'anchor = right edge LTR / left edge RTL (gsf.i sbe.c/sbe.a)');
check(hit.includes('(g.rect.top + g.rect.bottom) / 2'),
  'strip vertically centered on selection edge midpoint');
check(hit.includes('q.x >= anchorX && q.x <= anchorX + SELECTION_ROTATE_HANDLE_HIT_REACH'),
  'LTR strip x ∈ [anchor, anchor+reach]');
check(hit.includes('q.x >= anchorX - SELECTION_ROTATE_HANDLE_HIT_REACH && q.x <= anchorX'),
  'RTL strip x ∈ [anchor−reach, anchor]');
check(hit.includes('Math.abs(q.y - anchorY) <= SELECTION_ROTATE_HANDLE_HIT_HALF_H'),
  'strip y ∈ anchorY ± half-height');
check(!hit.includes('Math.hypot') && !hit.includes('SELECTION_HANDLE_HIT_RADIUS'),
  'endpoint circle hit removed (strip covers stem + endpoint + overshoot)');

// --- 可执行几何模型：1.4.2 ms1 条带 vs Harmony 等价 ---
const REACH = 104;
const HALF_H = 48;
// Harmony 模型：触点 p 先绕壳中心反旋 −θ，再测方向性条带。
function unrotate(p, cx, cy, rad) {
  const dx = p.x - cx;
  const dy = p.y - cy;
  const c = Math.cos(-rad);
  const s = Math.sin(-rad);
  return { x: cx + dx * c - dy * s, y: cy + dx * s + dy * c };
}
function stripHit(p, rect, rad, rtl) {
  const q = unrotate(p, (rect.left + rect.right) / 2,
    (rect.top + rect.bottom) / 2, rad);
  const anchorX = rtl ? rect.left : rect.right;
  const anchorY = (rect.top + rect.bottom) / 2;
  const inX = rtl
    ? (q.x >= anchorX - REACH && q.x <= anchorX)
    : (q.x >= anchorX && q.x <= anchorX + REACH);
  return inX && Math.abs(q.y - anchorY) <= HALF_H;
}
const R = { left: 100, top: 100, right: 300, bottom: 200 };
const midY = 150;

// LTR：茎中点（锚+28=茎半处，旧端点圆 Ø44 不覆盖）命中。
check(stripHit({ x: 328, y: midY }, R, 0, false),
  'model LTR mid-stem x=anchor+28 hits (was missed by Ø44 endpoint circle)');
// LTR：茎根恰在选区边上命中；条带末端 anchor+104 命中。
check(stripHit({ x: 300, y: midY }, R, 0, false) &&
  stripHit({ x: 404, y: midY }, R, 0, false),
  'model LTR strip covers [anchor, anchor+104] inclusive');
// LTR：条带外（anchor+105）与反向（anchor−1）拒绝。
check(!stripHit({ x: 405, y: midY }, R, 0, false) &&
  !stripHit({ x: 299, y: midY }, R, 0, false),
  'model LTR rejects beyond reach / inside selection');
// LTR 垂直边界：±48 命中、±49 拒绝。
check(stripHit({ x: 350, y: midY + 48 }, R, 0, false) &&
  stripHit({ x: 350, y: midY - 48 }, R, 0, false) &&
  !stripHit({ x: 350, y: midY + 49 }, R, 0, false) &&
  !stripHit({ x: 350, y: midY - 49 }, R, 0, false),
  'model LTR vertical tolerance = ±48 inclusive');
// RTL：条带镜像——锚=left=100，向左延至 −4；右侧不命中。
check(stripHit({ x: 72, y: midY }, R, 0, true) &&
  stripHit({ x: -4, y: midY }, R, 0, true) &&
  stripHit({ x: 100, y: midY }, R, 0, true),
  'model RTL strip covers [anchor−104, anchor] inclusive');
check(!stripHit({ x: -5, y: midY }, R, 0, true) &&
  !stripHit({ x: 101, y: midY }, R, 0, true) &&
  !stripHit({ x: 328, y: midY }, R, 0, true),
  'model RTL rejects beyond left reach / inside selection / right stem side');

// 旋转壳 θ=+30°：屏上茎实际沿壳轴伸出。构造壳系内茎中点
// q=(anchor+28, midY)，旋转 +θ 到屏上再测——应命中。
const th = Math.PI / 6;
const cx = 200; const cy = midY;
const qMid = { x: R.right + 28, y: midY };
const scr = {
  x: cx + (qMid.x - cx) * Math.cos(th) - (qMid.y - cy) * Math.sin(th),
  y: cy + (qMid.x - cx) * Math.sin(th) + (qMid.y - cy) * Math.cos(th),
};
check(stripHit(scr, R, th, false),
  'model rotated shell: on-axis mid-stem point hits after unrotation');
// 旋转壳下屏轴正右方点（不在壳轴上）→ 反旋后 y 偏离 → 拒绝。
const scrOffAxis = { x: R.right + 28, y: midY };
check(!stripHit(scrOffAxis, R, th, false),
  'model rotated shell: screen-horizontal point off shell axis rejected');

console.log(`d02-original-selection-rotate-hit: ${n} checks OK`);
