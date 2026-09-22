# ADR-0570 — z-order 菜单动作无条件清空选区（xsc.q → this.K.a()）

- 状态：Accepted
- Phase 601；对齐 `xsc.q`/`dhb` case6-9（decompiled_1.0.3）。
- 修正 ADR-0569 中 SEND_* "保留选区"的错误映射。

## 背景

Phase 600 判读 `dhb` case6-9 无独立 `fvbVar.a()`，误记 SEND_*
保留选区。实际四个 case 都走 `xscVar.q(ktcVar, lambda)`，而
`q()` 在 `zh9` 协程启动后**无条件** `this.K.a()`——SEND_*
同样清选区，且与操作是否生效无关（已置顶/置底也清）。

## 决策

`onSelectionMenuAction` 的 SEND_* 两个分支在调用 reorder 后
统一 `clearSelectionWithRegisterReset()`——挂在分发层而非
reorder 内部守卫之后，复刻 `q()` 的无条件终态（no-op 也清）。
`reorderSelected`/`reorderSelectedToExtreme` 内部保持选区无关。

## 偏差（fail-closed 记录）

1. 原版 `q()` 同步清选区、`zh9` 协程异步提交——短暂窗口内
   选区已消失而重排未落库；Harmony 同步重排后清，无中间态
   差异可见。
2. 原版 `K.a()` 亦清 `m`/`n` 绘制残留；Harmony 等价并入
   `clearSelectionWithRegisterReset`。

## 验证

- `docs/migration/replays/d02-original-menu-action-clears-selection.mjs`
  22 项断言（新增 SEND_* 分发层清空 + reorder 内部选区无关）。
- 证据：`docs/migration/evidence/original-zorder-clears-selection-2026-09-23.md`。
