// T-021 基于 op 栈的撤销/重做管理器（纯逻辑，禁止平台 import）
import { StrokeElementData } from '../core/model/StrokeTypes';

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
  // TRANSFORM_STROKES: 变换前后的 strokes 快照
  beforeStrokes: StrokeElementData[];
  afterStrokes: StrokeElementData[];
}

export class UndoRedoManager {
  private undoStack: UndoableAction[] = [];
  private redoStack: UndoableAction[] = [];
  private maxStackSize: number = 50;

  // 记录操作（清空 redoStack）
  push(action: UndoableAction): void {
    this.undoStack.push(action);
    if (this.undoStack.length > this.maxStackSize) {
      this.undoStack.shift();
    }
    this.redoStack = [];
  }

  // 撤销 → 返回需要执行的反向操作
  undo(): UndoableAction | null {
    const action: UndoableAction | undefined = this.undoStack.pop();
    if (action === undefined) {
      return null;
    }
    this.redoStack.push(action);
    return action;
  }

  // 重做 → 返回需要执行的正向操作
  redo(): UndoableAction | null {
    const action: UndoableAction | undefined = this.redoStack.pop();
    if (action === undefined) {
      return null;
    }
    this.undoStack.push(action);
    return action;
  }

  canUndo(): boolean {
    return this.undoStack.length > 0;
  }

  canRedo(): boolean {
    return this.redoStack.length > 0;
  }

  clear(): void {
    this.undoStack = [];
    this.redoStack = [];
  }
}
