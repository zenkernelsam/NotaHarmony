# ADR-0953 — search_item 写入路径 + 高亮模型

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `sq1`：UPSERT `ON CONFLICT(noteId,type,subId)
  DO UPDATE`，6 列绑定，pageId/rects 双可空。
- `klc.b`：逐元素 `l96.L0` 事务批量写；
  **rects 恒 `(byte[]) null`**（列保留未用）。
- `alc` = SearchHighlights{List}；`q1f` =
  内存高亮缓存 {documentState,textOrigin,query,rects}。
- `glc` = 投影行，不物化 rects。

## Harmony 决策

UPSERT→relationalStore 冲突替换；rects 列保留
恒 null（勿删）；高亮缓存等价。

## Parity 状态

等价。

## 验证

- `d02-search-writes.mjs`：12/12 通过。
