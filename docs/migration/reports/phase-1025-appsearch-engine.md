# Phase 1025 报告 — b50 AppSearch 引擎

## 范围

`b50` AppSearch impl + `f63` session + `vmc` 切换
细节。纯审计。

## 原版发现

- `b50 implements clc`：Mutex + `f63 extends wc6`
  AppSearch session + `getName="appsearch"`。
- 9 方法：d(ttf,str,mlc) 笔记内搜索/g(str,mlc)
  全局/i(str)→Serializable 详情/a clear/b bulk/
  c delete/e init/f flush/h 状态/j close。
- `vmc` 注入 `clc` + `ba6.o(getName())` 比较；
  默认引擎 `"appsearch"`。

## Harmony 决策

AppSearch fail-closed；Harmony 引擎=room-fts5。

## 产出

- 证据：`phase-1025-appsearch-engine.md`
- Fixture：`d02-appsearch-engine.mjs`（10/10）
- ADR-0969；全量 Replay 见本提交。
