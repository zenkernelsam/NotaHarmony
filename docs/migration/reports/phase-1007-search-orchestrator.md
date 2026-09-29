# Phase 1007 报告 — 搜索编排器

## 范围

clc 引擎接口、d6c/b50 双实现、vmc 编排器、hmc
三段重建、引擎切换偏好。纯审计。

## 原版发现

- `clc` 9 方法契约；实现 d6c(FTS5)+b50(appsearch)。
- `vmc` = 13-dep 编排器；`SearchDatabase.w/v/u` →
  ty5/oy5/oa4 三段 DAO；`hmc` 顺序执行。
- 引擎切换：`search_engine` prefs +
  `active_engine`(默认 appsearch)；变更→删旧库/目录
  + 重建 + `yn7.INDEXING` 遥测。

## Harmony 决策

单引擎化（无 FTS5/AppSearch）；契约与重建语义保留。

## 产出

- 证据：`phase-1007-search-orchestrator.md`
- Fixture：`d02-search-orchestrator.mjs`（12/12）
- ADR-0951；全量 Replay 见本提交。
