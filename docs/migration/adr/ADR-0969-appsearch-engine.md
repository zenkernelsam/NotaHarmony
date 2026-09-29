# ADR-0969 — b50 AppSearch 引擎

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `b50 implements clc`：Mutex + `f63`(extends `wc6`
  AppSearch session) + `getName="appsearch"`——
  9 个 clc 方法（d=笔记内搜索/g=全局搜索/
  i=Serializable 详情）。
- `vmc` 注入 `clc` + `ba6.o(name, getName())` 引擎
  比较；prefs `search_engine`/`active_engine`
  默认 `"appsearch"`。

## Harmony 决策

**AppSearch fail-closed**（Jetpack/GMS 依赖）；
Harmony 唯一引擎=`"room-fts5"`（d6c）；
`vmc` 引擎切换改 room-fts5-only，prefs 键保留。

## Parity 状态

fail-closed（平台）；room-fts5 路径等价。

## 验证

- `d02-appsearch-engine.mjs`：10/10 通过。
