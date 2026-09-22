// T-022 选区与变换（§25 精简：矩形/套索 + 移动/缩放/旋转 + 8 项菜单）
// 纯几何逻辑：禁止平台 import
import { StrokeElementData } from '../core/model/StrokeTypes';
import { Point2D, Rect2D, TransformMatrix } from '../core/model/GeometryTypes';
import { ImageElement, MathElement, ShapeElement, TextBlockElement } from '../core/model/ElementTypes';
import { OriginalSelectionGroup, resolveOriginalGroupSelection,
  OriginalGroupSelectionResult } from '../core/model/OriginalGroupSelection';
import { selectionPathHitsTextBlock } from '../core/model/TextBlockGeometry';
import { selectionPathHitsImageBlock } from '../core/model/ImageBlockGeometry';
import { selectionPathHitsMathBlock } from '../core/model/MathBlockGeometry';

export enum SelectionMode {
  RECTANGLE = 0,
  LASSO = 1,
}

export interface SelectionState {
  isActive: boolean;
  mode: SelectionMode;
  lassoPoints: Point2D[];        // 套索路径
  rect: Rect2D | null;           // 矩形选区
  selectedStrokeIds: string[];   // 选中笔画 ID
  selectedShapeIds: string[];
  selectedTextBlockIds: string[];
  selectedImageIds: string[];
  selectedMathIds: string[];
  selectedGroupIds: string[];
  transform: TransformMatrix;    // 当前变换矩阵（单位矩阵起始）
}

export class SelectionTool {
  private state: SelectionState;

  constructor() {
    this.state = {
      isActive: false,
      mode: SelectionMode.RECTANGLE,
      lassoPoints: [],
      rect: null,
      selectedStrokeIds: [],
      selectedShapeIds: [],
      selectedTextBlockIds: [],
      selectedImageIds: [],
      selectedMathIds: [],
      selectedGroupIds: [],
      transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    };
  }

  // 开始选区（touchDown）
  beginSelection(mode: SelectionMode, startPoint: Point2D): void {
    this.state.mode = mode;
    this.state.isActive = true;
    this.state.lassoPoints = [startPoint];
    this.state.rect = { left: startPoint.x, top: startPoint.y, right: startPoint.x, bottom: startPoint.y };
    this.state.selectedStrokeIds = [];
    this.state.selectedShapeIds = [];
    this.state.selectedTextBlockIds = [];
    this.state.selectedImageIds = [];
    this.state.selectedMathIds = [];
    this.state.selectedGroupIds = [];
    this.state.transform = [1, 0, 0, 0, 1, 0, 0, 0, 1];
  }

  // 更新选区（touchMove）
  updateSelection(currentPoint: Point2D): void {
    if (!this.state.isActive) {
      return;
    }
    if (this.state.mode === SelectionMode.LASSO) {
      this.state.lassoPoints.push(currentPoint);
    } else if (this.state.rect !== null) {
      this.state.rect = {
        left: Math.min(this.state.rect.left, currentPoint.x),
        top: Math.min(this.state.rect.top, currentPoint.y),
        right: Math.max(this.state.rect.right, currentPoint.x),
        bottom: Math.max(this.state.rect.bottom, currentPoint.y),
      };
    }
  }

  // 完成选区 → 计算命中笔画 ID
  finalizeSelection(strokes: StrokeElementData[], shapes: ShapeElement[] = [],
    textBlocks: TextBlockElement[] = [], images: ImageElement[] = [],
    groups: OriginalSelectionGroup[] = [], mathBlocks: MathElement[] = []): string[] {
    if (!this.state.isActive) {
      return [];
    }
    const ids: string[] = [];
    for (const s of strokes) {
      if (s.renderSpec.isPartialEraser === true) {
        continue;
      }
      if (this.state.mode === SelectionMode.RECTANGLE) {
        if (this.state.rect !== null && this.rectIntersects(this.state.rect, s.bounds)) {
          ids.push(s.id);
        }
      } else {
        // 套索：笔画 bounds 中心点在多边形内（射线法）
        const cx: number = (s.bounds.left + s.bounds.right) / 2;
        const cy: number = (s.bounds.top + s.bounds.bottom) / 2;
        if (this.pointInPolygon({ x: cx, y: cy }, this.state.lassoPoints)) {
          ids.push(s.id);
        }
      }
    }
    this.state.selectedStrokeIds = ids;
    const selectionPath: Point2D[] = this.selectionPath();
    const shapeIds: string[] = [];
    for (const shape of shapes) {
      if (this.elementBoundsSelected(shape.bounds)) {
        shapeIds.push(shape.id);
      }
    }
    this.state.selectedShapeIds = shapeIds;
    const textIds: string[] = [];
    for (const textBlock of textBlocks) {
      if (selectionPathHitsTextBlock(selectionPath, textBlock)) {
        textIds.push(textBlock.id);
      }
    }
    this.state.selectedTextBlockIds = textIds;
    const imageIds: string[] = [];
    for (const image of images) {
      if (selectionPathHitsImageBlock(selectionPath, image)) {
        imageIds.push(image.id);
      }
    }
    this.state.selectedImageIds = imageIds;
    const mathIds: string[] = [];
    for (const math of mathBlocks) {
      if (selectionPathHitsMathBlock(selectionPath, math)) {
        mathIds.push(math.id);
      }
    }
    this.state.selectedMathIds = mathIds;
    const availableIds: string[] = [];
    for (const stroke of strokes) {
      if (stroke.renderSpec.isPartialEraser !== true) {
        availableIds.push(stroke.id);
      }
    }
    for (const shape of shapes) {
      availableIds.push(shape.id);
    }
    for (const text of textBlocks) {
      availableIds.push(text.id);
    }
    for (const image of images) {
      availableIds.push(image.id);
    }
    for (const math of mathBlocks) {
      availableIds.push(math.id);
    }
    const grouped: OriginalGroupSelectionResult = resolveOriginalGroupSelection(
      ids.concat(shapeIds).concat(textIds).concat(imageIds).concat(mathIds), availableIds, groups);
    const selected: Set<string> = new Set<string>(grouped.entityIds);
    this.state.selectedStrokeIds = strokes.filter((stroke: StrokeElementData): boolean =>
      selected.has(stroke.id)).map((stroke: StrokeElementData): string => stroke.id);
    this.state.selectedShapeIds = shapes.filter((shape: ShapeElement): boolean =>
      selected.has(shape.id))
      .map((shape: ShapeElement): string => shape.id);
    this.state.selectedTextBlockIds = textBlocks.filter((text: TextBlockElement): boolean =>
      selected.has(text.id))
      .map((text: TextBlockElement): string => text.id);
    this.state.selectedImageIds = images.filter((image: ImageElement): boolean =>
      selected.has(image.id))
      .map((image: ImageElement): string => image.id);
    this.state.selectedMathIds = mathBlocks.filter((math: MathElement): boolean =>
      selected.has(math.id))
      .map((math: MathElement): string => math.id);
    this.state.selectedGroupIds = grouped.groupIds;
    return this.state.selectedStrokeIds.concat(this.state.selectedShapeIds)
      .concat(this.state.selectedTextBlockIds).concat(this.state.selectedImageIds)
      .concat(this.state.selectedMathIds);
  }

  // 移动选中内容（平移矩阵）
  moveSelected(dx: number, dy: number): TransformMatrix {
    const t: TransformMatrix = [1, 0, dx, 0, 1, dy, 0, 0, 1];
    this.state.transform = this.multiply(t, this.state.transform);
    return this.state.transform;
  }

  // 缩放（绕 center）
  scaleSelected(factor: number, center: Point2D): TransformMatrix {
    const t: TransformMatrix = [
      factor, 0, center.x * (1 - factor),
      0, factor, center.y * (1 - factor),
      0, 0, 1,
    ];
    this.state.transform = this.multiply(t, this.state.transform);
    return this.state.transform;
  }

  // 旋转（绕 center，弧度）
  rotateSelected(radians: number, center: Point2D): TransformMatrix {
    const cos: number = Math.cos(radians);
    const sin: number = Math.sin(radians);
    const t: TransformMatrix = [
      cos, -sin, center.x * (1 - cos) + center.y * sin,
      sin, cos, center.y * (1 - cos) - center.x * sin,
      0, 0, 1,
    ];
    this.state.transform = this.multiply(t, this.state.transform);
    return this.state.transform;
  }

  // 应用变换到笔画（修改 stroke.transform，返回新数组；不修改原始点数据）
  applyTransform(strokes: StrokeElementData[]): StrokeElementData[] {
    const result: StrokeElementData[] = [];
    for (const s of strokes) {
      const isSelected: boolean = this.state.selectedStrokeIds.indexOf(s.id) >= 0;
      if (isSelected) {
        result.push({
          id: s.id,
          pathPoints: s.pathPoints,
          cubicSegments: s.cubicSegments,
          splatPoints: s.splatPoints,
          renderSpec: s.renderSpec,
          transform: this.multiply(this.state.transform, s.transform),
          bounds: this.transformBounds(s.bounds, this.state.transform),
          maskPath: s.maskPath,
          customPath: s.customPath,
          fillPath: s.fillPath,
          fillColor: s.fillColor,
          styleMap: s.styleMap,
          audioStartTime: s.audioStartTime,
          audioDuration: s.audioDuration,
          originalCreate: s.originalCreate,
          isFinished: s.isFinished,
        });
      } else {
        result.push(s);
      }
    }
    return result;
  }

  // 删除选中 → 返回应删除的笔画 ID
  deleteSelected(): string[] {
    const ids: string[] = this.state.selectedStrokeIds.concat(this.state.selectedShapeIds)
      .concat(this.state.selectedTextBlockIds).concat(this.state.selectedImageIds)
      .concat(this.state.selectedMathIds);
    this.state.selectedStrokeIds = [];
    this.state.selectedShapeIds = [];
    this.state.selectedTextBlockIds = [];
    this.state.selectedImageIds = [];
    this.state.selectedMathIds = [];
    this.state.selectedGroupIds = [];
    this.deselect();
    return ids;
  }

  selectStrokeIds(ids: string[]): void {
    this.state.isActive = ids.length > 0;
    this.state.selectedStrokeIds = ids.slice();
    this.state.selectedShapeIds = [];
    this.state.selectedTextBlockIds = [];
    this.state.selectedImageIds = [];
    this.state.selectedMathIds = [];
    this.state.selectedGroupIds = [];
    this.state.lassoPoints = [];
    this.state.rect = null;
    this.state.transform = [1, 0, 0, 0, 1, 0, 0, 0, 1];
  }

  selectElementIds(strokeIds: string[], shapeIds: string[], textBlockIds: string[] = [],
    imageIds: string[] = [], groupIds: string[] = [], mathIds: string[] = []): void {
    this.state.isActive = strokeIds.length > 0 || shapeIds.length > 0 || textBlockIds.length > 0 ||
      imageIds.length > 0 || mathIds.length > 0;
    this.state.selectedStrokeIds = strokeIds.slice();
    this.state.selectedShapeIds = shapeIds.slice();
    this.state.selectedTextBlockIds = textBlockIds.slice();
    this.state.selectedImageIds = imageIds.slice();
    this.state.selectedMathIds = mathIds.slice();
    this.state.selectedGroupIds = groupIds.slice();
    this.state.lassoPoints = [];
    this.state.rect = null;
    this.state.transform = [1, 0, 0, 0, 1, 0, 0, 0, 1];
  }

  // 取消选择
  deselect(): void {
    this.state.isActive = false;
    this.state.selectedStrokeIds = [];
    this.state.selectedShapeIds = [];
    this.state.selectedTextBlockIds = [];
    this.state.selectedImageIds = [];
    this.state.selectedMathIds = [];
    this.state.selectedGroupIds = [];
    this.state.transform = [1, 0, 0, 0, 1, 0, 0, 0, 1];
  }

  getState(): SelectionState {
    return this.state;
  }

  // === 工具方法 ===
  private rectIntersects(a: Rect2D, b: Rect2D): boolean {
    return a.left <= b.right && a.right >= b.left && a.top <= b.bottom && a.bottom >= b.top;
  }

  private elementBoundsSelected(bounds: Rect2D): boolean {
    if (this.state.mode === SelectionMode.RECTANGLE) {
      return this.state.rect !== null && this.rectIntersects(this.state.rect, bounds);
    }
    const center: Point2D = {
      x: (bounds.left + bounds.right) / 2,
      y: (bounds.top + bounds.bottom) / 2,
    };
    return this.pointInPolygon(center, this.state.lassoPoints);
  }

  private selectionPath(): Point2D[] {
    if (this.state.mode === SelectionMode.LASSO) {
      return this.state.lassoPoints.slice();
    }
    if (this.state.rect === null) {
      return [];
    }
    return [
      { x: this.state.rect.left, y: this.state.rect.top },
      { x: this.state.rect.right, y: this.state.rect.top },
      { x: this.state.rect.right, y: this.state.rect.bottom },
      { x: this.state.rect.left, y: this.state.rect.bottom },
    ];
  }

  // 射线法判断点在多边形内
  private pointInPolygon(p: Point2D, polygon: Point2D[]): boolean {
    let inside: boolean = false;
    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      const xi: number = polygon[i].x;
      const yi: number = polygon[i].y;
      const xj: number = polygon[j].x;
      const yj: number = polygon[j].y;
      const intersect: boolean = ((yi > p.y) !== (yj > p.y)) &&
        (p.x < (xj - xi) * (p.y - yi) / (yj - yi) + xi);
      if (intersect) {
        inside = !inside;
      }
    }
    return inside;
  }

  // 3×3 行主序矩阵乘法
  private multiply(a: TransformMatrix, b: TransformMatrix): TransformMatrix {
    const result: TransformMatrix = [0, 0, 0, 0, 0, 0, 0, 0, 1];
    for (let row = 0; row < 3; row++) {
      for (let col = 0; col < 3; col++) {
        let sum: number = 0;
        for (let k = 0; k < 3; k++) {
          sum += a[row * 3 + k] * b[k * 3 + col];
        }
        result[row * 3 + col] = sum;
      }
    }
    return result;
  }

  // 用仿射矩阵变换矩形（取 4 角变换后的外接矩形）
  private transformBounds(bounds: Rect2D, m: TransformMatrix): Rect2D {
    const corners: Point2D[] = [
      { x: bounds.left, y: bounds.top },
      { x: bounds.right, y: bounds.top },
      { x: bounds.right, y: bounds.bottom },
      { x: bounds.left, y: bounds.bottom },
    ];
    let minX: number = Number.MAX_VALUE;
    let minY: number = Number.MAX_VALUE;
    let maxX: number = -Number.MAX_VALUE;
    let maxY: number = -Number.MAX_VALUE;
    for (const c of corners) {
      const x: number = m[0] * c.x + m[1] * c.y + m[2];
      const y: number = m[3] * c.x + m[4] * c.y + m[5];
      if (x < minX) {
        minX = x;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
    }
    return { left: minX, top: minY, right: maxX, bottom: maxY };
  }
}
