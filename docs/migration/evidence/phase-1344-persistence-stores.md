# Phase 1344 证据 — 本地 op→同步 op 持久化桥

来源：`data/{OriginalNoteBackgroundPersistence,
OriginalRecordingPersistence,OriginalPageOrderStore,
PageElementIdentity,PersistentHistoryMetadata,
OriginalRichTextStyleState,OriginalDefaultTemplateCodec}.ets`。

## `OriginalNoteBackgroundPersistence` = 本地→同步 op 桥

```
persistOriginalNoteBackground(store, noteId, ...):
  校验 note+selected-page 身份 + aligned page coverage
  unchanged 守卫 → allocateOperationIdentity(store, noteId)
    —— 分配 OperationIdentity{timestamp,siteId,clientTime}
  构造 StoredSyncedOperation{ORIGINAL_SET_METADATA,
    uploadImmediately: true, serverTime:null}
  → 本地 SET_METADATA 也走同步 op 机制
```

→ **本地变更经同一 op 管线**：本地 `SET_METADATA` 分配
CRDT 身份+落 `StoredSyncedOperation`+`uploadImmediately` —
— 本地编辑与远端同步共用 op 记录（对照原版 op-log）。

## 持久化/状态存储族

- `OriginalRecordingPersistence` —— 录音 op 持久化。
- `OriginalPageOrderStore` —— 页序存储。
- `PageElementIdentity` —— 页元素身份。
- `PersistentHistoryMetadata` —— 持久历史元数据。
- `OriginalRichTextStyleState` —— 富文本样式状态。
- `OriginalDefaultTemplateCodec` —— 默认模板编解码。

## Harmony 决策

本地编辑 = 分配 CRDT 身份+`StoredSyncedOperation`+
`uploadImmediately` —— 与远端同步同一 op 管线保真。

## 产出

- fixture `d02-persistence-stores.mjs`（10 断言）。
- ADR-1286；中文报告。
