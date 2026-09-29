# Phase 999 报告 — 同步编排器

## 范围

nr1 构造依赖与失效 Flow、wq1 Provider、q93 错误
枚举、pzb/ozb Result monad。纯审计。

## 原版发现

- `nr1` = 同步引擎：8 deps（oq1/nce/ssf/qr1/jl3/
  sxa/v2f/cx6）+ `pce` lazy×2 + Mutex×2 +
  `LinkedHashMap` 在途表 + `bsd.a(0)` 信号量。
- 三条共享失效 Flow：`ys2.r(db,false,tables,λ)` →
  `cq.u0(scope,ord,replay=1)` —— watch `ClientOp`、
  `{ClientOp,DraftNote}`、ClientOp 变体。
- `nr1.a`：`new zp1(ttf,uq9)` 批量 +
  `l96.L0` 事务插入。
- `nr1.b`：WAL 文件列表 Mutex 串行消费 +
  逐文件 `delete` + `t2f.a` 计时。
- `q93` = 四端点错误类目（CREATE/APPEND/
  BUNDLE_DOWNLOAD/SYNC_DOWNLOAD）。
- `pzb`/`ozb` = Kotlin Result；`wq1` = Provider。

## Harmony 决策

编排可平移（dataChange 事件≈失效 Flow）；端点
fail-closed。

## 产出

- 证据：`phase-999-sync-orchestrator.md`
- Fixture：`d02-sync-orchestrator.mjs`（16/16）
- ADR-0943；全量 Replay 见本提交。
