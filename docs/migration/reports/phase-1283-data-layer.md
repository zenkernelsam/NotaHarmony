# Phase 1283 报告 — 数据层架构普查

## 完成内容

- `com.gingerlabs.notability`（非混淆）：Room DB 群
  （NoteState/NoteAsset/NoteBundleMetadata/Learn/Search/
  SearchIndex/Settings/Toolbox/Transcription）+ 资产
  Download/Transfer/Upload Worker + `ops/synced` CRDT
  冲突异常（AccessDenied/CorruptedSyncedOp/
  StaleSyncedNote）+ `.ntb` 格式 + 转写→GCS + Play+
  Samsung 双 IAP + Retrofit REST + 共享内存 +
  GLMathNative 数学渲染 + 5 桌面 widget + MainActivity/
  NbApplication —— 完整数据架构。

## 产出

- evidence `phase-1283-data-layer.md`
- fixture `d02-data-layer.mjs`（10/10）
- ADR-1227
