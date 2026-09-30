# ADR-1227：数据层架构

## 状态

已接受（Phase 1283）。

## 决策

Room DB 群→`relationalStore`/`preferences`；Worker→
`WorkScheduler`；Retrofit→`rcp`/`http`；widget→
`FormExtensionAbility`；GCS/billing→fail-closed。

## 理由

`com.gingerlabs.notability` 数据层：Room DB（NoteState/
NoteAsset/NoteBundleMeta/Learn/Search/SearchIndex/
Settings/Toolbox/Transcription）+ CRDT synced-op 冲突
异常+资产 Worker+转写→GCS+双 IAP+Retrofit+共享内存+
GL 数学渲染+5 桌面 widget —— 完整数据架构。

## 后果

Harmony 数据层 = relationalStore+WorkScheduler+rcp+
FormExtensionAbility+手写 PDF/GL —— 语义映射，
GMS/billing fail-closed。
