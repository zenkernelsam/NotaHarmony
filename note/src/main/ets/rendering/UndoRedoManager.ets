// T-021 基于 op 栈的撤销/重做管理器（纯逻辑，禁止平台 import）
// 全笔记单栈：动作携带 pageId，保持跨页操作的真实时间顺序。
// 默认深度 50 是移植侧历史值，原版上限尚未从反编译代码确认，可通过构造参数调整。
import { StrokeElementData } from '../core/model/StrokeTypes';
import { TextBlockElement } from '../core/model/ElementTypes';
import { PageInfo } from '../core/model/NoteTypes';

// 可撤销的操作类型
export enum UndoableActionType {
  ADD_STROKE = 0,
  DELETE_STROKE = 1,
  ERASE_STROKES = 2,
  TRANSFORM_STROKES = 3,
  ADD_ELEMENT = 4,       // 文本框创建
  DELETE_ELEMENT = 5,    // 文本框删除
  REPLACE_ELEMENT = 6,   // 形状替换（笔画→形状，before=原笔画）
  ADD_PAGE = 7,
  DELETE_PAGE = 8,
  REORDER_PAGES = 9,
  PAGE_SETTINGS = 10,
}

interface ActionBase {
  type: UndoableActionType;
  pageId: string;
}

export interface AddStrokeAction extends ActionBase {
  type: UndoableActionType.ADD_STROKE;
  addedStrokes: StrokeElementData[];
}

export interface RemoveStrokeAction extends ActionBase {
  type: UndoableActionType.DELETE_STROKE | UndoableActionType.ERASE_STROKES;
  removedStrokes: StrokeElementData[];
  removedStrokeIndices: number[];
}

export interface TransformStrokesAction extends ActionBase {
  type: UndoableActionType.TRANSFORM_STROKES;
  beforeStrokes: StrokeElementData[];
  afterStrokes: StrokeElementData[];
}

export interface AddElementAction extends ActionBase {
  type: UndoableActionType.ADD_ELEMENT;
  addedElement: TextBlockElement;
}

export interface DeleteElementAction extends ActionBase {
  type: UndoableActionType.DELETE_ELEMENT;
  removedElements: TextBlockElement[];
}

export interface ReplaceElementAction extends ActionBase {
  type: UndoableActionType.REPLACE_ELEMENT;
  beforeStrokes: StrokeElementData[];
  afterStrokes: StrokeElementData[];
  beforeElements: TextBlockElement[];
  afterElements: TextBlockElement[];
}

export interface AddPageAction extends ActionBase {
  type: UndoableActionType.ADD_PAGE;
  pageAfter: PageInfo;
  pageOrderBefore: string[];
  pageOrderAfter: string[];
  pageStrokes: StrokeElementData[];
  pageTextBlocks: TextBlockElement[];
  selectedPageIdBefore: string;
  selectedPageIdAfter: string;
}

export interface DeletePageAction extends ActionBase {
  type: UndoableActionType.DELETE_PAGE;
  pageBefore: PageInfo;
  pageOrderBefore: string[];
  pageOrderAfter: string[];
  pageStrokes: StrokeElementData[];
  pageTextBlocks: TextBlockElement[];
  selectedPageIdBefore: string;
  selectedPageIdAfter: string;
}

export interface ReorderPagesAction extends ActionBase {
  type: UndoableActionType.REORDER_PAGES;
  pageOrderBefore: string[];
  pageOrderAfter: string[];
}

export interface PageSettingsAction extends ActionBase {
  type: UndoableActionType.PAGE_SETTINGS;
  pageBefore: PageInfo;
  pageAfter: PageInfo;
}

export type UndoableAction = AddStrokeAction | RemoveStrokeAction | TransformStrokesAction |
  AddElementAction | DeleteElementAction | ReplaceElementAction | AddPageAction | DeletePageAction |
  ReorderPagesAction | PageSettingsAction;

export interface PageContentSnapshot {
  strokes: StrokeElementData[];
  textBlocks: TextBlockElement[];
}

export interface EditorHistoryBridge {
  pushPageAction: (action: UndoableAction) => void;
  captureCurrentPage: () => PageContentSnapshot;
  preparePageRemoval: (pageId: string) => void;
  cancelPageRemoval: (pageId: string) => void;
  flushCurrentPage: () => Promise<boolean>;
}

export class UndoRedoManager {
  private undoStack: UndoableAction[] = [];
  private redoStack: UndoableAction[] = [];
  private maxStackSize: number;

  constructor(maxStackSize: number = 50) {
    this.maxStackSize = Math.max(1, maxStackSize);
  }

  // 记录操作（清空 redoStack）
  push(action: UndoableAction): void {
    this.undoStack.push(action);
    if (this.undoStack.length > this.maxStackSize) {
      this.undoStack.shift();
    }
    this.redoStack = [];
  }

  peekUndo(): UndoableAction | null {
    return this.undoStack.length > 0 ? this.undoStack[this.undoStack.length - 1] : null;
  }

  commitUndo(expected: UndoableAction): boolean {
    if (this.peekUndo() !== expected) {
      return false;
    }
    this.undoStack.pop();
    this.redoStack.push(expected);
    return true;
  }

  peekRedo(): UndoableAction | null {
    return this.redoStack.length > 0 ? this.redoStack[this.redoStack.length - 1] : null;
  }

  commitRedo(expected: UndoableAction): boolean {
    if (this.peekRedo() !== expected) {
      return false;
    }
    this.redoStack.pop();
    this.undoStack.push(expected);
    return true;
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
