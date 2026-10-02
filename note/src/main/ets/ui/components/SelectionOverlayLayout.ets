import { Rect2D } from '../../core/model/GeometryTypes';

export const SELECTION_MENU_BUTTON_WIDTH: number = 130;
export const SELECTION_MENU_BUTTON_HEIGHT: number = 40;
export const SELECTION_MENU_BUTTON_GAP: number = 4;
// 原版 gsf.b 角柄：双层圆——半径 12dp 白（p52.e）+半径 10dp 蓝
//（gsf.a=#FF4278FF），视觉直径 24/20vp；命中 = f15=44/zoom 文档方框。
export const SELECTION_HANDLE_SIZE: number = 12;
export const SELECTION_HANDLE_DOT_OUTER: number = 24;
export const SELECTION_HANDLE_DOT_INNER: number = 20;
// 原版 gsf.e 旋转柄（msc.c selectionHasRotationHandle 入口）：锚点=右
//（RTL 左）边中点，水平茎 56vp（56dp/zoom），端点双层圆半径 16dp 白 /
// 14dp d=#FF444DE0，茎描边同色 2dp。
export const SELECTION_ROTATE_HANDLE_STEM: number = 56;
export const SELECTION_ROTATE_DOT_OUTER: number = 32;
export const SELECTION_ROTATE_DOT_INNER: number = 28;
// 原版 ms1:667-683 旋转柄命中域 = 茎锚点起向柄侧的条带矩形：
// 触及 = (72 + 32)/zoom 文档单位（茎 56 + 端点 Ø32 + 过冲 32），
// 半高 = (16 + 32)/zoom = 48；屏上等效 104vp 触及 × ±48vp 半高。
export const SELECTION_ROTATE_HANDLE_HIT_REACH: number = 104;
export const SELECTION_ROTATE_HANDLE_HIT_HALF_H: number = 48;
const SELECTION_MENU_EDGE_MARGIN: number = 8;
// 原版 mnm.c → abn.e → i3b 菜单定位：锚 = mfc.n(sbe) 屏矩形
// odf.c(·,72,72) 各边膨胀 72 屏 px（清除旋转柄茎 56+端点 16=72 区），
// abn.c 去窗 insets±12dp 后 i3b 裁决——LTR（yj8.F）先放锚框
// 右侧 +margin，溢出回退左侧，再溢出右缘夹取；RTL 镜像；
// 纵向 = 锚框中心 − 菜单高/2（odf.a 中心点）夹取容器内。
export function selectionMenuSideInflateVp(): number {
  return px2vp(72);
}

export interface SelectionOverlayPosition {
  x: number;
  actionY: number;
  pasteY: number;
}

export function selectionOverlayPosition(rect: Rect2D, containerWidth: number,
  containerHeight: number, hasPaste: boolean, rtl: boolean = false): SelectionOverlayPosition {
  const safeWidth: number = finitePositive(containerWidth,
    SELECTION_MENU_BUTTON_WIDTH + SELECTION_MENU_EDGE_MARGIN * 2);
  const buttonCount: number = hasPaste ? 2 : 1;
  const groupHeight: number = buttonCount * SELECTION_MENU_BUTTON_HEIGHT +
    (buttonCount - 1) * SELECTION_MENU_BUTTON_GAP;
  const safeHeight: number = finitePositive(containerHeight,
    groupHeight + SELECTION_MENU_EDGE_MARGIN * 2);
  const inflate: number = selectionMenuSideInflateVp();
  const maxX: number = Math.max(SELECTION_MENU_EDGE_MARGIN,
    safeWidth - SELECTION_MENU_EDGE_MARGIN - SELECTION_MENU_BUTTON_WIDTH);
  // i3b：主侧 = 锚框膨胀边 + 余量（LTR 右 / RTL 左）；溢出 → 对侧；
  // 仍溢出 → 容器缘夹取。
  const primaryX: number = rtl ?
    rect.left - inflate - SELECTION_MENU_BUTTON_WIDTH :
    rect.right + inflate;
  const fallbackX: number = rtl ?
    rect.right + inflate :
    rect.left - inflate - SELECTION_MENU_BUTTON_WIDTH;
  let x: number;
  if (!rtl) {
    if (primaryX + SELECTION_MENU_BUTTON_WIDTH <= safeWidth) {
      x = primaryX;
    } else if (fallbackX >= 0) {
      x = fallbackX;
    } else {
      x = maxX;
    }
  } else {
    if (primaryX >= 0) {
      x = primaryX;
    } else if (fallbackX + SELECTION_MENU_BUTTON_WIDTH <= safeWidth) {
      x = fallbackX;
    } else {
      x = SELECTION_MENU_EDGE_MARGIN;
    }
  }
  x = clamp(finite(x, SELECTION_MENU_EDGE_MARGIN), SELECTION_MENU_EDGE_MARGIN, maxX);
  const maxY: number = Math.max(SELECTION_MENU_EDGE_MARGIN,
    safeHeight - SELECTION_MENU_EDGE_MARGIN - groupHeight);
  const centerY: number = (finite(rect.top, 0) + finite(rect.bottom, 0)) / 2;
  const actionY: number = clamp(centerY - groupHeight / 2,
    SELECTION_MENU_EDGE_MARGIN, maxY);
  return {
    x: x,
    actionY: actionY,
    pasteY: actionY + SELECTION_MENU_BUTTON_HEIGHT + SELECTION_MENU_BUTTON_GAP,
  };
}

export function standalonePastePosition(containerWidth: number): number {
  const safeWidth: number = finitePositive(containerWidth,
    SELECTION_MENU_BUTTON_WIDTH + SELECTION_MENU_EDGE_MARGIN * 2);
  return clamp(16, SELECTION_MENU_EDGE_MARGIN,
    Math.max(SELECTION_MENU_EDGE_MARGIN,
      safeWidth - SELECTION_MENU_EDGE_MARGIN - SELECTION_MENU_BUTTON_WIDTH));
}

function finite(value: number, fallback: number): number {
  return Number.isFinite(value) ? value : fallback;
}

function finitePositive(value: number, fallback: number): number {
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}
