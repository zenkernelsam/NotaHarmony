# Phase 1005 证据 — 索引变更队列（l79 DAO + c79 实体 + 处理流）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `c79` = NoteIndexableChanges 实体

```java
final class c79 {
    ttf a;    // noteId
    List b;   // ids（BLOB 序列化列表）
    List c;   // pageIds
    List d;   // newPageInsertLocations
    boolean e; // mainBodyText
    boolean f; // initialLoad
    boolean g; // processing
    int h;    // chunkIndex
}
```

- 字段↔列一一对应 Phase 1003 DDL：
  `{noteId, ids, pageIds, newPageInsertLocations,
  mainBodyText, initialLoad, processing, chunkIndex}`。
- `c79.a(...)` = copy() 合成构造（`i & 16` 掩码默认）。

## `l79` = DAO（x5c db + wp1 insert + sh8）

```java
wp1 INSERT OR ABORT: 8 列 VALUES(?,?,?,?,?,?,?,?)
```

方法：
- `f(l79, c79, ff2)` static —— 变更入队（事务）。
- `a(c79, n8e)` —— 单变更处理/合并。
- `b()` —— `SELECT DISTINCT noteId WHERE processing=
  FALSE` + TRUE 两路（i79 λ 23-40 行），以及
  `SELECT * WHERE processing=TRUE ORDER BY chunkIndex`
  （57 行）—— **两阶段出队**：FALSE=待认领、
  TRUE=处理中按块序。
- `c/d/e(ttf)` —— 按 note 查询/删除（e49 λ）。
- `ya9`：`DELETE WHERE noteId IN (...)` 批量清理。

## 处理流程（推断+实证）

```
编辑/载入 → l79.f 入队 (processing=FALSE 初始)
worker   → l79.b: DISTINCT noteId(processing=FALSE)
         → 认领翻 processing=TRUE
         → e49: SELECT * WHERE noteId=? AND processing
                =TRUE ORDER BY chunkIndex —— 逐块消费
         → 成功→删行（ya9/q55），失败→la4 台账
           (indexerVersion=2)
```

- `chunkIndex` = 大笔记分块索引，避免长事务。
- `mainBodyText`/`initialLoad` 标志指导搜索项
  （MAIN_BODY_TEXT 类型）的生成范围。
- `la4` = FailedIndexedNote{noteId, errorClass,
  timestamp} + toString 内嵌 `indexerVersion=2` 常量。

## HarmonyOS 决策

- 队列表平移 relationalStore；`processing` 标志 +
  `chunkIndex` 序 + 失败台账语义保留。
- 认领-处理-删除两阶段协议不变。

## 产出

- fixture `d02-index-changes-queue.mjs`（14 断言）。
- ADR-0949；中文报告。
