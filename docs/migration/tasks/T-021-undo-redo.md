# T-021 Undo/Redo

## 目标

实现基于 op 栈的撤销/重做管理器，集成到工具栏 Undo/Redo 按钮。

## 参考

- 知识库：REVERSE_ANALYSIS.md §14（Undo/Redo = Command 模式/操作栈）
- 契约：`note/src/main/ets/core/model/OpTypes.ets`（OpType/Op）
- 依赖：T-019（EditorToolbar 的 Undo/Redo 按钮）、T-020（NoteCanvasView 笔画完成回调）

## 实现要求

### 创建文件

`note/src/main/ets/rendering/UndoRedoManager.ets`

### 接口设计

```typescript
import { StrokeElementData } from '../core/model/StrokeTypes';
import { Point2D } from '../core/model/GeometryTypes';

// 可撤销的操作类型
export enum UndoableActionType {
  ADD_STROKE = 0,
  DELETE_STROKE = 1,
  ERASE_STROKES = 2,
  TRANSFORM_STROKES = 3,
}

export interface UndoableAction {
  type: UndoableActionType;
  // ADD_STROKE: 添加的笔画
  addedStroke: StrokeElementData | null;
  // DELETE_STROKE / ERASE_STROKES: 被删除的笔画列表
  removedStrokes: StrokeElementData[];
  // TRANSFORM_STROKES: 变换前的 strokes 快照
  beforeStrokes: StrokeElementData[];
  afterStrokes: StrokeElementData[];
}

export class UndoRedoManager {
  private undoStack: UndoableAction[] = [];
  private redoStack: UndoableAction[] = [];
  private maxStackSize: number = 50;

  // 记录操作（清空 redoStack）
  push(action: UndoableAction): void

  // 撤销 → 返回需要执行的反向操作
  undo(): UndoableAction | null

  // 重做 → 返回需要执行的正向操作
  redo(): UndoableAction | null

  canUndo(): boolean
  canRedo(): boolean
  clear(): void
}
```

### 集成到 NoteCanvasView

- 笔画完成时 → `push({ type: ADD_STROKE, addedStroke })`
- 擦除整条时 → `push({ type: ERASE_STROKES, removedStrokes })`
- Undo 按钮 → `undo()` → 根据 action.type 反向操作画布
- Redo 按钮 → `redo()` → 正向操作画布
- 工具栏 Undo/Redo 按钮的 enabled 状态绑定 canUndo()/canRedo()

### 鸿蒙特有约束

- 禁止平台 import（纯逻辑模块）。
- maxStackSize = 50，超出时 shift() 丢弃最旧操作。
- push 时清空 redoStack（新操作后不可重做旧操作）。
- Undo/Redo 后需要触发 StrokeLayerManager.rebuildFromStrokes() 重绘。

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] 画一笔 → Undo → 笔画消失
- [ ] Undo 后 → Redo → 笔画恢复
- [ ] 画两笔 → Undo → Undo → 两笔都消失
- [ ] 新操作后 Redo 按钮禁用
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-021-完成.md`
