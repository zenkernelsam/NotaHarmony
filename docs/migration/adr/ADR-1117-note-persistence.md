# ADR-1117：data/note 持久化（3 Room + 密封传输工人）

## 状态

已接受（Phase 1173）。

## 决策

- 3 Room（`NoteAsset`/`NoteBundleMetadata`/`NoteState`）→
  Harmony **RDB**；拆库语义保留（assets/metadata/state）。
- `NoteAssetTransferWorker`（密封 CoroutineWorker，
  Download/Upload）→ Harmony 后台任务 + 密封等价。
- `ops/synced` 5 同步异常语义保留。

## 理由

`extends x5c`×3 + `extends CoroutineWorker` 密封 +
`⸹{Download,Upload}` + `extends Exception`×5。

## 后果

Harmony 笔记持久化 = 3 RDB 域；资产传输 = 后台任务
（Down/Up 两类）；同步错误分类沿用 5 异常。
