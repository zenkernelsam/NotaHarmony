# Phase 601 — z-order 菜单动作无条件清空选区（xsc.q → this.K.a()）

- 日期：2026-09-23
- 结果：已实现对齐（修正 Phase 600 的 SEND_* 映射）
- 证据：`docs/migration/evidence/original-zorder-clears-selection-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0570-original-zorder-clears-selection.md`
- Replay：`docs/migration/replays/d02-original-menu-action-clears-selection.mjs`（22 项断言）

## 背景

`dhb` case6-9（SEND_FORWARD/BACKWARD/TO_FRONT/TO_BACK）全部
经 `xscVar.q(ktcVar, lambda)` 分发；`q()` 在 `zh9` 协程启动后
无条件 `this.K.a()`——z-order 动作同样清选区，no-op 亦清。
Phase 600 仅看 case 块内无 `fvbVar.a()` 而误记"保留"。

Harmony 的 `reorderSelected`/`reorderSelectedToExtreme` 原保留
选区（no-op early-return 亦然）。

## 实现

`onSelectionMenuAction` 两个 SEND_* 分支在 reorder 调用后统一
`clearSelectionWithRegisterReset()`——分发层清空，复刻 `q()`
无条件终态；reorder 内部保持选区无关。

## 偏差

见 ADR-0570 §偏差：同步重排替代原版协程窗口；寄存器重置并入
清空。

## 验证

- `node docs/migration/replays/d02-original-menu-action-clears-selection.mjs` → 22/22。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
