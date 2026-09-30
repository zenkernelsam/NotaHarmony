# ADR-1286：本地→同步 op 持久化桥

## 状态

已接受（Phase 1344）。

## 决策

本地编辑 = 分配 CRDT 身份 + `StoredSyncedOperation`
+`uploadImmediately` —— 与远端同步同一 op 管线。

## 理由

`OriginalNoteBackgroundPersistence`：本地 `SET_METADATA`
经 `allocateOperationIdentity` 分配 `{timestamp,siteId}`，
包装为 `StoredSyncedOperation{uploadImmediately:true}`
落库 —— 本地变更与远端同步共用 op-log 机制（对照
原版 op 记录）；配套 Recording/PageOrder/ElementIdentity/
HistoryMetadata/RichTextStyle/Template 存储族。

## 后果

本地/远端编辑统一 op 管线 —— CRDT 一致性保真。
