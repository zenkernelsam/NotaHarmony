# Phase 1118 报告 — core/ 命名包锚定

## 完成内容

- `core/model/a` = 根页 id 哨兵 `opId{0,-1}→seq0` + note 聚合。
- `core/model/b` = ops→th7 持久列表物化器。
- `c8d` = `SharedMemoryByteArena`；`core/` 包图锚定。

## 产出

- evidence `phase-1118-named-core.md`
- fixture `d02-named-core.mjs`（10/10）
- ADR-1062
