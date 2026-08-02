# T-022 选区与变换

## 目标

实现选区工具（矩形框选 + 自由套索）+ 选中后的移动/缩放/旋转变换 + 精简选区菜单（8 项）。

## 参考

- 知识库：REVERSE_ANALYSIS.md §25（Drawn/Lasso 模型 + 22 项菜单 + 统一 transform 矩阵 zy7）、§33（SelectionCollisionResult）
- 契约：`note/src/main/ets/core/model/GeometryTypes.ets`（TransformMatrix/Rect2D/Point2D）
- 依赖：T-019（Selection 工具按钮）、T-021（变换操作可 Undo）

## 实现要求

### 创建文件

1. `note/src/main/ets/rendering/SelectionTool.ets`（选区逻辑）
2. `note/src/main/ets/ui/components/SelectionOverlay.ets`（选区边框 UI）

### SelectionTool.ets

```typescript
import { StrokeElementData } from '../core/model/StrokeTypes';
import { Point2D, Rect2D, TransformMatrix } from '../core/model/GeometryTypes';

export enum SelectionMode { RECTANGLE = 0, LASSO = 1 }

export interface SelectionState {
  isActive: boolean;
  mode: SelectionMode;
  lassoPoints: Point2D[];        // 套索路径
  rect: Rect2D | null;           // 矩形选区
  selectedStrokeIds: string[];   // 选中笔画 ID
  transform: TransformMatrix;    // 当前变换矩阵（单位矩阵起始）
}

export class SelectionTool {
  private state: SelectionState;

  // 开始选区（touchDown）
  beginSelection(mode: SelectionMode, startPoint: Point2D): void
  // 更新选区（touchMove）
  updateSelection(currentPoint: Point2D): void
  // 完成选区 → 计算命中笔画
  finalizeSelection(strokes: StrokeElementData[]): string[]
  // 移动选中内容
  moveSelected(dx: number, dy: number): TransformMatrix
  // 缩放
  scaleSelected(factor: number, center: Point2D): TransformMatrix
  // 旋转
  rotateSelected(radians: number, center: Point2D): TransformMatrix
  // 应用变换到笔画（修改 stroke.transform）
  applyTransform(strokes: StrokeElementData[]): StrokeElementData[]
  // 删除选中
  deleteSelected(): string[]
  // 取消选择
  deselect(): void

  getState(): SelectionState
}
```

### 命中检测

- RECTANGLE: 笔画 bounds 与选区 rect 相交 → 选中
- LASSO: 笔画 bounds 中心点在套索多边形内 → 选中（射线法）

### SelectionOverlay.ets

选中后显示：
- 虚线边框（选中区域的 bounds）
- 4 个角控制点（缩放）
- 顶部旋转手柄
- 底部菜单按钮行（Copy/Cut/Delete/Forward/Backward/FlipH/FlipV/Deselect）

### 鸿蒙特有约束

- SelectionTool 禁止平台 import（纯几何）。
- SelectionOverlay 是 @Component（Canvas 或 Stack + Shape 绘制边框）。
- 变换修改的是 stroke.transform 矩阵，不修改原始 pathPoints。
- 单位矩阵 = [1,0,0,0,1,0,0,0,1]。
- 矩阵乘法手动实现（3×3）。

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] Selection 工具可框选笔画（矩形模式）
- [ ] 选中后显示虚线边框 + 控制点
- [ ] 拖拽可移动选中笔画
- [ ] Delete 按钮可删除选中笔画
- [ ] Deselect 取消选择
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-022-完成.md`
