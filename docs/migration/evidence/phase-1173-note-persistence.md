# Phase 1173 证据 — data/note 持久化（3 Room DB + 密封传输工人）

来源：`data/note/{ops,assets,state}/`。

## 3 Room DB（`x5c`）

- `assets/NoteAssetDatabase` —— 笔记资产（图片/录音等
  大文件元数据）。
- `ops/database/NoteBundleMetadataDatabase` —— 笔记包
  元数据。
- `state/NoteStateDatabase` —— 笔记状态（同步/打开态）。

笔记持久化**拆 3 库**：assets / bundle-metadata / state。

## `NoteAssetTransferWorker` = 密封传输工人

```java
abstract NoteAssetTransferWorker extends CoroutineWorker
  ⸹ {NoteAssetDownloadWorker, NoteAssetUploadWorker}  // Kotlin 密封
    Download/Upload . c(k19) suspend                   // 传输逻辑
```

`NoteAssetTransferWorker` = **Kotlin 密封类**（metadata
`⸹` 列出允许子类 Download/Upload）—— 资产传输
生命周期统一抽象。

## `ops/synced/` ×5 同步异常

```java
AccessDeniedException          // 无权限
CorruptedSyncedOpException     // op 损坏
NoteHasNoOpsException          // 无 op
NoteOpsNotFoundException       // op 未找到
StaleSyncedNoteException       // 过期笔记
```

## Harmony 决策

- 3 Room → Harmony **RDB**（拆库语义保留：assets/
  metadata/state 分表或分库）。
- 密封传输工人 → Harmony 后台任务 + sealed 等价
  （`type` union 或 abstract）。
- 5 同步异常语义保留。

## 产出

- fixture `d02-note-persistence.mjs`（10 断言）。
- ADR-1117；中文报告。
