# Phase 1174 证据 — data/ 剩余 Room DB 清单（×5）

来源：`data/{settings,toolbar,search,transcription}/`。

## 5 Room `x5c` DB

```java
settings/database/SettingsDatabase        // 设置持久化
toolbar/database/ToolboxDatabase          // 工具箱配置
search/engine/room/SearchIndexDatabase    // 搜索索引
search/database/SearchDatabase            // 搜索结果库
transcription/database/TranscriptionDatabase // 转录持久化
```

全部 `abstract X extends x5c`（Room）+ `X_Impl` 生成类。

## data/ Room 总账（命名包）

| DB | 域 |
|----|----|
| NoteAssetDatabase | 笔记资产 |
| NoteBundleMetadataDatabase | 笔记包元数据 |
| NoteStateDatabase | 笔记状态 |
| RawLibraryStateDatabase | 库状态 |
| LearnDatabase | learn/onboarding |
| SearchIndexDatabase | 搜索索引 |
| SearchDatabase | 搜索结果 |
| SettingsDatabase | 设置 |
| ToolboxDatabase | 工具箱 |
| TranscriptionDatabase | 转录 |

**10 个 Room DB** —— 全应用持久化拆 10 库（每域一库，
符合 Room 单域模式）。

## Harmony 决策 — RDB

全部 Room `x5c` → Harmony **RDB**（`relationalStore`）；
拆库语义保留（10 域各一库或一库多表）。

## 产出

- fixture `d02-data-rooms.mjs`（10 断言）。
- ADR-1118；中文报告。
