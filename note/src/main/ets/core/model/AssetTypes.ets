// T-005 资源引用类型（契约 phase-1-data-model.md §3.7，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块

// 资源状态
export enum AssetStatus {
  PENDING = 0,
  LOCAL = 1,
  UPLOADED = 2,
  DOWNLOADED = 3,
  FAILED = 4,
}

// 笔记资源（对应 NoteAsset 表）
export interface NoteAsset {
  assetHash: string;      // SHA-256 哈希（主键）
  status: AssetStatus;
  noteIds: string[];      // 关联笔记（多对多）
  fileSize: number;
  mimeType: string;
  localPath: string | null;
}
