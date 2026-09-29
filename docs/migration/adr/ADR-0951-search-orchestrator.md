# ADR-0951 — 搜索编排器（clc/vmc/hmc）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `clc` = SearchEngine 接口 9 方法；实现
  `d6c`(room-fts5) + `b50`(appsearch)。
- `vmc` = 13-dep 编排器；SearchDatabase 三段 DAO
  `w()/v()/u()` → ty5/oy5/oa4。
- `hmc` = 顺序重建协程 p→q→r。
- SharedPreferences `search_engine`/`active_engine`
  默认 `"appsearch"`；切换删库重建 + INDEXING 遥测。

## Harmony 决策

单引擎（relationalStore LIKE 路径）；clc 契约平移；
vmc 退化为注入；appsearch fail-closed。

## Parity 状态

功能降级（单引擎）。

## 验证

- `d02-search-orchestrator.mjs`：12/12 通过。
