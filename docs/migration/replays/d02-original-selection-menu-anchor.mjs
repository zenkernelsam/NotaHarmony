// Phase 1466 — 选区动作菜单锚定 = mnm.c/abn.e/i3b 移植：
// 锚 = mfc.n(sbe) 屏矩形（u64.h 密度缩放 − 画布原点）+ odf.c 72px 膨胀
// （旋转柄茎 56+端点 16=72 区清除）→ abn.c 去 insets±12dp → i3b：
// LTR(yj8.F) 先锚框右侧，溢出回退左侧，再溢出右缘夹取；RTL 镜像；
// 纵向 = odf.a 锚框中心 − 菜单高/2 夹取容器。
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';

const L = 'note/src/main/ets/ui/components/SelectionOverlayLayout.ets';
const O = 'note/src/main/ets/ui/components/SelectionOverlay.ets';
const V = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const lay = readFileSync(L, 'utf8');
const ov = readFileSync(O, 'utf8');
const view = readFileSync(V, 'utf8');

let n = 0, failed = 0;
const check = (ok, name) => {
  if (ok) { console.log('ok - ' + name); } else { failed++; console.log('FAIL - ' + name); }
  n++;
};

// --- 锚框膨胀：odf.c(ku7, 72, 72) = 各边 −72/+72 屏 px ---
check(lay.includes('selectionMenuSideInflateVp') && lay.includes('px2vp(72)'),
  'anchor rect inflated by 72 screen px via px2vp (odf.c)');
// --- i3b 侧向裁决：LTR 右侧优先 ---
check(lay.includes('rect.right + inflate') && lay.includes('rect.left - inflate'),
  'side anchor = inflated rect edge (i3b i9/i2)');
check(lay.indexOf('primaryX + SELECTION_MENU_BUTTON_WIDTH <= safeWidth') > 0,
  'primary side accepted when menu fits (i9 + w <= i7)');
check(lay.includes('fallbackX >= 0') && lay.includes('x = maxX'),
  'right overflow → left side (i2 >= 0) → right-edge clamp (i7 - w)');
// --- RTL 镜像 ---
check(lay.includes('rtl ?') && lay.includes('rect.left - inflate - SELECTION_MENU_BUTTON_WIDTH'),
  'RTL mirrors: left side primary (yj8.G branch)');
// --- 纵向：锚框中心 − 菜单高/2 夹取 ---
check(lay.includes('centerY - groupHeight / 2') && lay.includes('(finite(rect.top'),
  'menu vertically centered on anchor (odf.a center y - h/2)');
// --- 接线 ---
check(ov.includes('false, this.selectionRotateHandleRtl'),
  'overlay passes RTL flag (yj8 → abn.c LayoutDirection)');
check(view.includes('this.overlayWidth, this.overlayHeight, false,') &&
  view.includes('this.selectionRotateHandleRtl)'),
  'isInSelectionMenu shares the side-anchored layout');

// --- 可执行模型（i3b measure 等价，inflate=24vp @3x） ---
const INFLATE = 24, W = 130, H = 40, EDGE = 8;
const menuPos = (rect, cw, ch, rtl = false) => {
  const primary = rtl ? rect.left - INFLATE - W : rect.right + INFLATE;
  const fallback = rtl ? rect.right + INFLATE : rect.left - INFLATE - W;
  let x;
  if (!rtl) {
    if (primary + W <= cw) x = primary;
    else if (fallback >= 0) x = fallback;
    else x = Math.max(EDGE, cw - EDGE - W);
  } else {
    if (primary >= 0) x = primary;
    else if (fallback + W <= cw) x = fallback;
    else x = EDGE;
  }
  x = Math.min(Math.max(x, EDGE), Math.max(EDGE, cw - EDGE - W));
  const cy = (rect.top + rect.bottom) / 2;
  const y = Math.min(Math.max(cy - H / 2, EDGE), Math.max(EDGE, ch - EDGE - H));
  return { x, y };
};
{
  // 选区 (100,100)-(300,200)，容器 800x600 → 菜单右置 (324,130)。
  const p = menuPos({ left: 100, top: 100, right: 300, bottom: 200 }, 800, 600);
  assert(p.x === 324 && p.y === 130, 'LTR: right of inflated rect, vertically centered');
  n++;
  // 选区贴右缘 (660,100)-(780,200)：右置溢出 → 回退左侧 (660-24-130=506)。
  const p2 = menuPos({ left: 660, top: 100, right: 780, bottom: 200 }, 800, 600);
  assert(p2.x === 506 && p2.y === 130, 'right overflow → left side fallback');
  n++;
  // 超宽选区 (50,100)-(750,200)：两侧皆溢出 → 右缘夹取 662。
  const p3 = menuPos({ left: 50, top: 100, right: 750, bottom: 200 }, 800, 600);
  assert(p3.x === 662, 'both sides overflow → right-edge clamp');
  n++;
  // RTL：选区居中 → 主侧左置 (100-24-130=-54<0) → 回退右侧 324。
  const p4 = menuPos({ left: 100, top: 100, right: 300, bottom: 200 }, 800, 600, true);
  assert(p4.x === 324, 'RTL: left overflows → falls back to right side');
  n++;
  // RTL 正常左置：选区 (500,100)-(700,200) → 500-24-130=346。
  const p5 = menuPos({ left: 500, top: 100, right: 700, bottom: 200 }, 800, 600, true);
  assert(p5.x === 346, 'RTL: left side primary');
  n++;
  // 纵向居中夹取：选区中心 y=590 → 570 超界 → 夹 552 (600-8-40)。
  const p6 = menuPos({ left: 100, top: 560, right: 300, bottom: 620 }, 800, 600);
  assert(p6.y === 552, 'vertical center clamped to container');
  n++;
}

console.log(`D02_ORIGINAL_SELECTION_MENU_ANCHOR_OK TOTAL=${n} FAILED=${failed}`);
process.exit(failed === 0 ? 0 : 1);
