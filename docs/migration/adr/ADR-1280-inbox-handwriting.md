# ADR-1280：同步收件箱校验 + 手写转换

## 状态

已接受（Phase 1337）。

## 决策

入站同步 = noteId+信封+server-time 强制有序+去重；
手写转换 = `RecognitionProvider` 抽象+能力策略
（MyScript 本体 fail-closed，编排保真）。

## 理由

`SyncedOperationInbox.validateIncomingSyncedBatch`：
noteId 匹配+`validateOriginalSyncedOperation` 信封
校验+强制 server-time 有序（否则 throw）+
`duplicateOperationCount` 去重+u64 排序。手写层
`OriginalHandwriting*`（Conversion/Planner/Policy/
Locale/Context/Selection）对照 `dhb` 转换编排。

## 后果

入站同步严格校验；手写转换编排保真（引擎 fail-closed）。
