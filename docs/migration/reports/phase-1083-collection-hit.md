# Phase 1083 报告 — 父集合 + 命中测试

## 完成内容

- `ba6.M` = 实体父集合解析（`m4c` 字段，组归属；
  tombstone/null → 默认 `o()`）。
- `ba6.O` = y-偏移命中（`ehf`{index,id,offset}）；
  `ba6.P` = 包围盒相交过滤。

## 产出

- evidence `phase-1083-collection-hit.md`
- fixture `d02-collection-hit.mjs`（10/10）
- ADR-1027
