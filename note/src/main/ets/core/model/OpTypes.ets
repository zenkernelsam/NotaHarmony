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
  // 擦除
  ERASE_PARTIAL = 20,   // 像素擦除（写入 maskPath）
  ERASE_WHOLE = 21,     // 整条删除
  // 笔记级
  UPDATE_TITLE = 30,
  UNDO = 40,
  REDO = 41,
  // Harmony recovery checkpoint. This is deliberately distinct from the
  // original app's fine-grained FlatBuffer operations.
  PAGE_SNAPSHOT = 50,
}

// 单条操作
export interface Op {
  opId: string;
  noteId: string;
  opType: OpType;
  payload: Uint8Array;     // 序列化后的操作内容
  clientTime: number;      // 客户端时间戳 ms
}

// op 序列化器接口
export interface OpSerializer {
  serialize(op: Op): Uint8Array;
  deserialize(data: Uint8Array): Op;
}
