import { Rect2D } from '../../core/model/GeometryTypes';

export const SELECTION_MENU_BUTTON_WIDTH: number = 130;
export const SELECTION_MENU_BUTTON_HEIGHT: number = 40;
export const SELECTION_MENU_BUTTON_GAP: number = 4;
const SELECTION_MENU_EDGE_MARGIN: number = 8;
const SELECTION_MENU_SELECTION_GAP: number = 8;

export interface SelectionOverlayPosition {
  x: number;
  actionY: number;
  pasteY: number;
}

export function selectionOverlayPosition(rect: Rect2D, containerWidth: number,
  containerHeight: number, hasPaste: boolean): SelectionOverlayPosition {
  const safeWidth: number = finitePositive(containerWidth,
    SELECTION_MENU_BUTTON_WIDTH + SELECTION_MENU_EDGE_MARGIN * 2);
  const buttonCount: number = hasPaste ? 2 : 1;
  const groupHeight: number = buttonCount * SELECTION_MENU_BUTTON_HEIGHT +
    (buttonCount - 1) * SELECTION_MENU_BUTTON_GAP;
  const safeHeight: number = finitePositive(containerHeight,
    groupHeight + SELECTION_MENU_EDGE_MARGIN * 2);
  const maxX: number = Math.max(SELECTION_MENU_EDGE_MARGIN,
    safeWidth - SELECTION_MENU_EDGE_MARGIN - SELECTION_MENU_BUTTON_WIDTH);
  const x: number = clamp(finite(rect.left, SELECTION_MENU_EDGE_MARGIN),
    SELECTION_MENU_EDGE_MARGIN, maxX);
  const belowY: number = finite(rect.bottom, 0) + SELECTION_MENU_SELECTION_GAP;
  const maxY: number = Math.max(SELECTION_MENU_EDGE_MARGIN,
    safeHeight - SELECTION_MENU_EDGE_MARGIN - groupHeight);
  const aboveY: number = finite(rect.top, 0) - SELECTION_MENU_SELECTION_GAP - groupHeight;
  const actionY: number = belowY <= maxY ? belowY : clamp(aboveY, SELECTION_MENU_EDGE_MARGIN, maxY);
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
