// Phase 1474 — 1.4.2 Ctrl+V 粘贴锚点 = 剪贴板负载原界中心 +
// min(w*0.1,30)（f2:183-210 → m86 byte20）。
// Original evidence (decompiled_1.4.2):
//   f2.java:182-211（!pa8.W 块内、`db8.r&&pa8.a(n,pa8.H=50=V)`）：
//     jt2 = bd8.K.b() = ot2.b() = pt2.d.a —— **剪贴板负载原界**
//       （ot2.d copy / ot2.a duplicate / ot2.e cut 构建 lt2 负载时
//       `this.d.a = lt2VarH.b()` 记录），且 gqf 剪贴板描述符兼容
//       门；null → ea1.p(qc8.a) 空事件 no-op；
//     bde.F = u64.b(jt2.b) 负载中心 + s64.a(fMin,fMin)，
//       fMin = min((sbe.c−sbe.a)*0.1, 30) 双轴等值；
//     屏坐标 ku7=exj.c 视口矩形 zx7.z 半开检查 —— x∉[a,c) 或
//       y∉[b,d) → bde.F = exj.c() 视口中心回退；
//     → tee.I(z(), m86(bd8, bde, jt2, byte20)) 粘贴事件。
//   与当前选区无关——复制后 ome.a() 已清选，锚定的是负载原位。
// Harmony：Ctrl+V/PASTE 支改 strokeClipboard.payloadBounds()
//   （unionBounds 公开访问器 ≡ pt2.a）；锚 = 负载界中心 +
//   min(w*0.1,30) 页面单位；canvasToScreen 半开视口检查 →
//   越界回退视口中心；直达 pasteClipboard（绕过
//   selectionPasteTarget 的选区中心优先——原版锚定负载）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const CLIP = 'note/src/main/ets/rendering/StrokeClipboard.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const clip = readFileSync(CLIP, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- StrokeClipboard.payloadBounds 访问器（ot2.b/pt2.a 等价） ---
const pbIdx = clip.indexOf('payloadBounds(): Rect2D | null');
check(pbIdx > 0, 'payloadBounds accessor present');
const pb = clip.slice(pbIdx, pbIdx + 500);
check(pb.includes('hasContent()') && pb.includes('this.unionBounds()'),
  'payloadBounds = unionBounds gated by hasContent (pt2.a 记录语义)');
check(pb.includes('return null'),
  'empty clipboard → null (ot2.b jt2==null → qc8 空事件等价)');

// --- Ctrl+V 支：负载锚 + 视口回退 ---
const vAnchor = 'ORIGIN_KEYCODE_V) ||';
const vStart = canvas.indexOf(vAnchor);
check(vStart > 0, 'Ctrl+V dispatch branch present');
const vBlock = canvas.slice(vStart, vStart + 1800);
check(vBlock.includes('this.strokeClipboard.payloadBounds()'),
  'anchor source = clipboard payload bounds (jt2.b, 非选区界)');
check(vBlock.includes('Math.min(payloadW * 0.1, 30)'),
  'nudge = min(payload width*0.1, 30) page units (f2 fMin 同款)');
check(vBlock.includes('/ 2 + nudge'),
  'anchor = payload bounds center + equal x/y nudge (u64.b+s64.a)');
check(vBlock.includes('this.viewport.canvasToScreen(cx, cy)') &&
  vBlock.includes('targetScreen.x >= 0 && targetScreen.x < this.canvasCtx.width'),
  'viewport half-open containment check (zx7.z 等价)');
check(vBlock.includes('this.viewport.screenToCanvas(') &&
  vBlock.includes('this.canvasCtx.width / 2'),
  'off-viewport → viewport center fallback (exj.c() 等价)');
check(vBlock.includes('this.pasteClipboard(target)'),
  'direct pasteClipboard call — bypasses selectionPasteTarget ' +
  'selection-center preference (m86 bde.F 直锚)');
check(!vBlock.includes('onSelectionMenuAction(SelectionMenuAction.PASTE)'),
  'keyboard paste no longer detours through selection-center target');
check(vBlock.includes('isUp && this.clipboardAvailable'),
  'UP + clipboard gate (jt2==null→qc8 no-op 等价)');

// --- 选区存在时锚定负载而非选区：fixture pin 语义 ---
const spt = canvas.slice(canvas.indexOf('private selectionPasteTarget()'),
  canvas.indexOf('private selectionPasteTarget()') + 700);
check(spt.includes('!this.selectionVisible'),
  'selectionPasteTarget still prefers selection center — but keyboard ' +
  'Ctrl+V no longer uses it (菜单粘贴路径保留原位语义)');

// --- 可执行模型：锚点裁决 ---
function pasteAnchor(payload, viewportScreen, zoom) {
  // 原版：payload bounds center + nudge，屏坐标半开视口检查→回退
  if (payload === null) return { kind: 'noop' };
  const w = payload.right - payload.left;
  const nudge = w > 0 ? Math.min(w * 0.1, 30) : 30;
  const cx = (payload.left + payload.right) / 2 + nudge;
  const cy = (payload.top + payload.bottom) / 2 + nudge;
  const sx = (cx - viewportScreen.ox) * zoom; // canvasToScreen 简化模型
  const sy = (cy - viewportScreen.oy) * zoom;
  if (sx >= 0 && sx < viewportScreen.w && sy >= 0 && sy < viewportScreen.h) {
    return { kind: 'payload', x: cx, y: cy };
  }
  return { kind: 'viewport-center' };
}
const vp = { ox: 0, oy: 0, w: 1000, h: 800 };
const a1 = pasteAnchor({ left: 100, top: 100, right: 300, bottom: 200 }, vp, 1);
check(a1.kind === 'payload' && a1.x === 220 && a1.y === 170,
  'model: payload [100,100,300,200] center(200,150)+min(20)→(220,170)');
const a2 = pasteAnchor({ left: 0, top: 0, right: 1000, bottom: 800 }, vp, 1);
check(a2.kind === 'payload' && a2.x === 530 && a2.y === 430,
  'model: wide payload clamps nudge to 30');
const a3 = pasteAnchor({ left: -5000, top: -5000, right: -4900, bottom: -4900 }, vp, 1);
check(a3.kind === 'viewport-center',
  'model: off-viewport payload → viewport center (exj.c 回退)');
const a4 = pasteAnchor(null, vp, 1);
check(a4.kind === 'noop', 'model: null payload → qc8 no-op');
// 半开边界：nudge 后 x ≥ 右缘 → 回退
const a5 = pasteAnchor({ left: 990, top: 0, right: 1010, bottom: 10 },
  { ox: 0, oy: 0, w: 1000, h: 800 }, 1);
check(a5.kind === 'viewport-center',
  'model: nudged x at/exceeding right edge → half-open fallback');

console.log(`d02-original-paste-anchor: ${n} checks OK`);
