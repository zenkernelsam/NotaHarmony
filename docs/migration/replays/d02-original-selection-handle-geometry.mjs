// Phase 1450 — 1.4.2 gsf.b/gsf.e 选区手柄几何与式样对齐。
// Original evidence (decompiled_1.4.2/sources/defpackage/gsf.java):
//   gsf.b:30-42 — 角柄：u64.c(sbe) 四角各绘双层圆——
//     qe4.u0(p52.e, 12/f2, corner) 半径 12dp 白圆 +
//     u0(a, 10/f2, corner) 半径 10dp #FF4278FF 蓝圆。
//   gsf.e:84-103 — 旋转柄：锚点 i(sbe,dir)=右（RTL 左）边中点；
//     U(d, i, packed(dx=56/f2·dir, w=2/f2)) = #FF444DE0 2dp 茎线；
//     端点圆 u0(p52.e,16/f2)/u0(d,14/f2) 于 i+(56/f2, 1/f2)。
//   gsf.i:164-168 — 锚点 = (dir==LTR? sbe.c:sbe.a, (b+d)/2)。
// Harmony：覆盖层双层圆角柄 + 右边中点 56vp 茎 + 端点双层圆；
//   selectionRotateHandleAt 命中域同步迁至茎端点。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const OVERLAY = 'note/src/main/ets/ui/components/SelectionOverlay.ets';
const LAYOUT = 'note/src/main/ets/ui/components/SelectionOverlayLayout.ets';
const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const overlay = readFileSync(OVERLAY, 'utf8').replace(/\r\n/g, '\n');
const layout = readFileSync(LAYOUT, 'utf8').replace(/\r\n/g, '\n');
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 常量：gsf.b/e 尺寸 ---
check(layout.includes('SELECTION_HANDLE_DOT_OUTER: number = 24') &&
  layout.includes('SELECTION_HANDLE_DOT_INNER: number = 20'),
  'corner dots = gsf.b radius 12dp white + 10dp blue (diameter 24/20vp)');
check(layout.includes('SELECTION_ROTATE_HANDLE_STEM: number = 56') &&
  layout.includes('SELECTION_ROTATE_DOT_OUTER: number = 32') &&
  layout.includes('SELECTION_ROTATE_DOT_INNER: number = 28'),
  'rotate stem 56vp + dot radius 16/14dp (diameter 32/28vp)');

// --- 角柄：双层圆（白底+蓝心），四角 ---
const cornerBlock = overlay.slice(overlay.indexOf('ForEach(['),
  overlay.indexOf('`${corner.x},${corner.y}`') + 40);
check(cornerBlock.includes('SELECTION_HANDLE_DOT_OUTER') &&
  cornerBlock.includes('SELECTION_HANDLE_DOT_INNER'),
  'corner handles are two-tone stacked circles (gsf.b u0×2)');
check(cornerBlock.includes("'#FFFFFFFF'") && cornerBlock.includes("'#FF4278FF'"),
  'corner outer = p52.e white, inner = gsf.a #FF4278FF');
check(cornerBlock.includes('x: corner.x - SELECTION_HANDLE_DOT_OUTER / 2'),
  'corner dots centered on selection corners');

// --- 旋转柄：右边中点锚 + 茎 + 端点双层圆 ---
check(overlay.includes('SELECTION_ROTATE_HANDLE_STEM') &&
  overlay.includes('this.selectionRotateHandleRtl') &&
  overlay.includes('this.selectionRect.left - SELECTION_ROTATE_HANDLE_STEM') &&
  overlay.includes('this.selectionRect.right,') &&
  overlay.includes('(this.selectionRect.top + this.selectionRect.bottom) / 2'),
  'rotate stem anchored at right-edge midpoint, RTL left (gsf.i/gsf.e ±56)');
check(overlay.includes("'#FF444DE0'"),
  'rotate stem+dot inner = gsf.d #FF444DE0');
check(overlay.includes('SELECTION_ROTATE_DOT_OUTER') &&
  overlay.includes('SELECTION_ROTATE_DOT_INNER'),
  'rotate endpoint = two-tone dot (16dp white / 14dp #444DE0)');
check(!overlay.includes('SELECTION_ROTATE_HANDLE_OFFSET') &&
  !canvas.includes('SELECTION_ROTATE_HANDLE_OFFSET'),
  'legacy top-edge rotate handle removed (gsf.e is right-edge stem)');

// --- 命中域同步：selectionRotateHandleAt 迁至茎端点 ---
const hit = canvas.slice(canvas.indexOf('private selectionRotateHandleAt('),
  canvas.indexOf('private selectionRotateHandleAt(') + 800);
check(hit.includes('this.selectionRect.right + SELECTION_ROTATE_HANDLE_STEM') &&
  hit.includes('(this.selectionRect.top + this.selectionRect.bottom) / 2') &&
  hit.includes('SELECTION_HANDLE_HIT_RADIUS'),
  'rotate-handle hit zone = stem endpoint circle, 22vp radius');

// --- 覆盖层手柄门控保持（deselectMode/photoImport/handlesHidden） ---
check(overlay.includes('!this.deselectMode && !this.photoImportLeaseActive') &&
  overlay.includes('!this.selectionHandlesHidden'),
  'handle block gated on deselectMode/photoImportLease/handlesHidden');

// --- Phase 1458 — RTL 左锚旋转柄（yj8.G→gsf.i sbe.a/gsf.e −56/ms1:525 +π） ---
check(overlay.includes('@Prop selectionRotateHandleRtl'),
  'overlay exposes RTL rotate-handle prop');
check(canvas.includes('@State selectionRotateHandleRtl') &&
  canvas.includes('i18n.isRTL(i18n.System.getSystemLanguage())'),
  'RTL state driven by i18n isRTL (yj8.G equivalent)');
const hitRtl = canvas.slice(canvas.indexOf('private selectionRotateHandleAt('),
  canvas.indexOf('private selectionRotateHandleAt(') + 900);
check(hitRtl.includes('this.selectionRect.left - SELECTION_ROTATE_HANDLE_STEM') &&
  hitRtl.includes('this.selectionRect.right + SELECTION_ROTATE_HANDLE_STEM'),
  'hit zone mirrors anchor side: RTL→left−stem / LTR→right+stem');
check(canvas.includes('selectionRotateHandleRtl: this.selectionRotateHandleRtl'),
  'RTL prop wired from canvas state to overlay');

console.log(`d02-original-selection-handle-geometry: ${n} checks OK`);
