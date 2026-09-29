# Phase 1017 报告 — nr1 同步引擎方法图

## 范围

`nr1` 9 依赖 + 完整方法图。纯审计。

## 原版发现

- `nr1` 依赖：oq1/nce/ssf/qr1/jl3/sxa/v2f + 双
  em8 Mutex + LinkedHashMap + 三 sfb Flow。
- 方法图：`d/e` DAO/DB 访问器、`a` zp1 事务、
  `b` 上传 suspend、`g` jq1 查询、`f` dr1 tick、
  `c` Flow 收集、`i`(761)/`j`(8622) 巨型协程。
- **`j` = 主同步状态机**——8622 指令单元的 suspend
  coroutine，JADX 反编译失败；行为需从调用图+
  上下游契约推断（标注"部分推断"）。

## Harmony 决策

ArkTS async 状态机重写；`i`/`j` 按可证契约重构。

## 产出

- 证据：`phase-1017-sync-engine-map.md`
- Fixture：`d02-sync-engine-map.mjs`（10/10）
- ADR-0961；全量 Replay 见本提交。
