// T-004 操作流类型（契约 phase-1-data-model.md §3.5，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块

// op 类型枚举（基于 §21 已确认 + 合理扩展）
export enum OpType {
  // 页面操作
  CREATE_PAGE = 0,
  DELETE_PAGE = 1,
  UPDATE_PAGE = 2,      // 尺寸/模板变更
  REORDER_PAGES = 3,
  // 元素操作
  INSERT_ELEMENTS = 10,
  DELETE_ELEMENTS = 11,
  TRANSFORM_ELEMENTS = 12,
  UPDATE_ELEMENT_STYLE = 13,
  REPLACE_ELEMENTS = 14,
  REORDER_ELEMENTS = 15,
  // 擦除
  ERASE_PARTIAL = 20,   // 像素擦除（写入 maskPath）
  ERASE_WHOLE = 21,     // 整条删除
  // 笔记级
  UPDATE_TITLE = 30,
  // Harmony history companion for original Group visibility/authoring. The private-sync
  // operations remain separate ORIGINAL_* rows and this payload only restores editor history.
  GROUP_ELEMENTS = 31,
  UNDO = 40,
  REDO = 41,
  // Harmony recovery checkpoint. This is deliberately distinct from the
  // original app's fine-grained FlatBuffer operations.
  PAGE_SNAPSHOT = 50,
  // Original 1.0.3 payload table retained for the private sync transport.
  ORIGINAL_DELETE_ENTITIES = 60,
  ORIGINAL_CREATE_RECORDING = 61,
  ORIGINAL_CREATE_PAGE = 62,
  ORIGINAL_CREATE_INK = 63,
  ORIGINAL_MODIFY_INK = 64,
  ORIGINAL_MODIFY_POSITIONS = 65,
  ORIGINAL_MODIFY_BLOCK = 66,
  ORIGINAL_MODIFY_SHAPE = 67,
  ORIGINAL_CREATE_SHAPE = 68,
  ORIGINAL_CREATE_GROUP = 69,
  ORIGINAL_MODIFY_GROUP = 70,
}

// History movement is metadata on a concrete mutation, not a replacement mutation type.
export enum HistoryEffect {
  PUSH = 0,
  UNDO = 1,
  REDO = 2,
}

// Mirrors Notability 1.0.3 pnf. NONE deliberately disables implicit coalescing.
export enum HistoryCoalesceTrack {
  NONE = 0,
  INSERT_TEXT = 1,
  REMOVE_TEXT = 2,
  CREATE_INK = 3,
}

export interface HistoryMetadata {
  actionId: string;
  effect: HistoryEffect;
  coalesceTrack: HistoryCoalesceTrack;
  actionTime: number;
}

// 单条操作
export interface Op {
  opId: string;
  noteId: string;
  opType: OpType;
  payload: Uint8Array;     // 序列化后的操作内容
  clientTime: number;      // 客户端时间戳 ms
  // Original Id(timestamp, site). Optional only for legacy in-memory/checkpoint values;
  // every v18 operation_log row and every new production append carries both fields.
  opTimestamp?: number;
  editorSiteId?: number;
  uploadImmediately?: boolean;
  history?: HistoryMetadata;
}

export interface SequencedOp {
  sequence: number;
  op: Op;
}

export interface OpSyncMetadata {
  noteId: string;
  editorSiteId: number;
  editorId: string;
  creatorId: string;
  createdAt: number;
  updatedAt: number;
  syncedOpCount: number;
  maxOpTimestamp: number;
  // Original server time is an unsigned 64-bit value. Decimal text avoids JS number truncation.
  maxServerTime: string | null;
  schemaVersion: number;
  uploadedThroughSequence: number;
  ackedThroughSequence: number;
}

export interface OpCompactionResult {
  safeThroughSequence: number;
  deletedOperationCount: number;
}

// op 序列化器接口
export interface OpSerializer {
  serialize(op: Op): Uint8Array;
  deserialize(data: Uint8Array): Op;
}
