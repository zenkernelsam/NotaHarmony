// T-004 op 流存储接口（契约 phase-1-data-model.md §3.9，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块
// 注：契约 §3.9 import 了 OpSerializer，但接口内未使用；为满足零诊断验收仅 import Op（不涉及签名变更）
import { Op, OpCompactionResult, OpSyncMetadata, SequencedOp } from '../model/OpTypes';

export interface OpStore {
  // 追加 op
  appendOp(op: Op): Promise<void>;
  // 读取笔记的全部 op（按 clientTime 排序）
  getOps(noteId: string): Promise<Op[]>;
  // 读取笔记的增量 op
  getOpsSince(noteId: string, sinceTime: number): Promise<Op[]>;
  // 删除笔记的全部 op
  deleteOps(noteId: string): Promise<void>;
  // 获取 op 计数
  getOpCount(noteId: string): Promise<number>;
  // Sync transport reads in durable append order and acknowledges only ordered prefixes.
  getPendingOps(noteId: string, limit: number): Promise<SequencedOp[]>;
  getSyncMetadata(noteId: string): Promise<OpSyncMetadata>;
  markOpsUploaded(noteId: string, throughSequence: number): Promise<void>;
  acknowledgeUploadedOps(noteId: string, throughSequence: number, maxServerTime: number): Promise<void>;
  compactAcknowledgedOps(noteId: string): Promise<OpCompactionResult>;
}
