# Phase 1337 证据 — 同步收件箱校验 + 手写转换层

来源：`data/SyncedOperationInbox.ets`+`core/adaptation/
OriginalHandwriting*.ets`（8 文件）。

## `SyncedOperationInbox` = 入站同步校验

```
validateIncomingSyncedBatch(noteId):
  逐 op validateIncomingSyncedOperation:
    validateIncomingSyncedOperationMetadata(expectedNoteId)
      —— noteId 匹配
    validateOriginalSyncedOperation —— 信封有效性
    强制 server-time 有序（否则 throw 'not server-time
      ordered'）
  duplicateOperationCount —— 去重计数
  compareUnsignedLongDecimal —— u64 排序比较
```

→ 入站同步 = 严格校验（noteId+信封+server-time 有序
强制+重复计数）—— 对照原版 `SyncedOp` 校验语义。

## `OriginalHandwriting*` 手写转换层（8 文件）

- `ConversionCoordinator`/`ConversionPlanner`/`Conversion
  TextPolicy` —— 手写→文本/数学转换编排（对照 `dhb`）。
- `LocaleAdapter`/`ProviderCapabilityPolicy`/`Recognition
  ContextAdapter`/`SelectionAdapter` —— 区域/能力/上下文/
  选区适配。

## Harmony 决策

入站 = noteId+信封+server-time 强校验+去重；手写转换 =
`RecognitionProvider` 抽象 + 能力策略（MyScript 本体
fail-closed，编排保真）。

## 产出

- fixture `d02-inbox-handwriting.mjs`（10 断言）。
- ADR-1280；中文报告。
