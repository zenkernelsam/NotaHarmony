# ADR-1242：Room 数据库层

## 状态

已接受（Phase 1298）。

## 决策

Room → Harmony `@relationalStore`（RdbStore per feature）
+ `@preferences` for settings —— 持久化架构映射。

## 理由

7 个 Room DB（Learn/Search+Index/Settings/Toolbox/
Transcription/NoteAsset/NoteState）= 模块化分库 + Room
`_Impl` 生成代码 —— 每特性隔离持久化。

## 后果

Harmony 持久化 = per-feature RdbStore + Preferences —
— 隔离+独立迁移语义保真。
