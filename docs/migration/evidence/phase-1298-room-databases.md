# Phase 1298 证据 — Room 数据库层（持久化架构）

来源：`data/*/database/*Database.java` + `*_Impl`。

## 7 个 Room 数据库

```
data/learn/database/LearnDatabase        — 学习/测验（LearnJob
                                          /QuizOp/StudyItems/Summary）
data/search/database/SearchDatabase      — 搜索结果
   search/database/SearchIndexDatabase   — FTS 索引（search/search_item）
data/settings/database/SettingsDatabase  — 应用设置
data/toolbar/database/ToolboxDatabase    — 工具箱
data/transcription/database/TranscriptionDatabase — 转写
data/note/assets/NoteAssetDatabase       — 资产
data/note/state/NoteStateDatabase        — 笔记状态
```

各带 `*_Impl`（Room 生成代码 + migration/DAO 分发）——
**模块化分库**持久化架构。

## 语义

- 每特性一库（learn/search/settings/toolbox/transcription/
  noteAsset/noteState）—— 隔离 + 独立迁移。
- Room `_Impl` = 编译期生成（openHelper + DAO impl +
  EntityAdapter）。
- 覆盖：AI 学习/搜索 FTS/设置/工具/转写/资产/笔记状态。

## Harmony 决策

Room → Harmony **关系型数据库 `@relationalStore`**
（RdbStore per feature）+ 实体映射或 **Preferences**
for settings —— 持久化架构语义保真。

## 产出

- fixture `d02-room-databases.mjs`（10 断言）。
- ADR-1242；中文报告。
