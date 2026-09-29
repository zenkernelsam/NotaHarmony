# Phase 1024 证据 — 索引追踪三元组

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 三表

| 表 | 列 | 角色 |
|---|---|---|
| `IndexedTitle` | `noteId PK, title TEXT` | **标题暂存**
  ——indexer 先写 noteId+title |
| `IndexedNote` | `noteId PK` | **已索引标记**
  ——`INSERT INTO IndexedNote SELECT noteId FROM
  IndexedTitle` |
| `FailedIndexedNote` | `noteId PK, errorClass,
  timestamp, indexerVersion` | **失败账本**
  ——indexerVersion=2 |

## 两阶段索引模式

```sql
INSERT INTO IndexedNote (noteId)
  SELECT noteId FROM IndexedTitle
```

- 阶段1：indexer 写 `IndexedTitle`(noteId+title)。
- 阶段2：`IndexedNote` 从 `IndexedTitle` SELECT
  ——标题索引完成的笔记标记进 IndexedNote。
- 阶段3：失败入 `FailedIndexedNote`（errorClass+
  timestamp+indexerVersion=2）——重试靠
  indexerVersion 不匹配。

## `indexerVersion=2`

- `FailedIndexedNote.indexerVersion`——索引器版本；
  升级后旧失败记录自然过期（版本不匹配即重试）。

## HarmonyOS 决策

三表平移 relationalStore；两阶段 INSERT-SELECT
保留；indexerVersion=2 常量移植。

## 产出

- fixture `d02-index-tracking.mjs`（10 断言）。
- ADR-0968；中文报告。
