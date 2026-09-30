# Phase 1308 报告 — Op 分类法分歧

## 完成内容

- 对比 Harmony `core/model/OpTypes` vs 原版 `haa`
  32-op：Harmony = **`ORIGINAL_*` 桥接**（镜像
  CREATE_PAGE/INSERT_TEXT/MODIFY_*）+ **本地超集**
  （UNDO/REDO 作同步 op、ERASE_PARTIAL/WHOLE、
  GROUP_ELEMENTS、REORDER_PAGES、PAGE_SNAPSHOT、
  INSERT/REMOVE/REPLACE/TRANSFORM_ELEMENTS）——
  原版字符级 CRDT（INSERT_CHAR/REVIVE_CHARS 墓碑+
  本地 undo）vs Harmony 元素级（含 ORIGINAL_ 桥接）
  —— 粒度/undo/tombstone 语义分歧已记录。

## 产出

- evidence `phase-1308-op-taxonomy.md`
- fixture `d02-op-taxonomy.mjs`（10/10）
- ADR-1252
