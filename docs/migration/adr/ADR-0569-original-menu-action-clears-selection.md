# ADR-0569 — 选区菜单动作完成后清空选区（dhb → fvbVar.a() 终态）

- 状态：Accepted
- Phase 600；对齐 `dhb` dsc 分发/`lg2`/`fvb.a`（decompiled_1.0.3）。

## 背景

原版选区菜单动作的成功终态统一为 `fvbVar.a()`（选区置空）：
COPY/CUT/DUPLICATE/GROUP/UNGROUP/DELETE/FLIP_H/FLIP_V/LOCK/
UNLOCK；DUPLICATE 随后由 `lg2.e` 重选粘贴副本。STYLE、
EDIT_MATH、CROP、DESELECT、MORE 保留选区。
（SEND_* 经 `xsc.q` 内部 `this.K.a()` 亦清空——本 ADR 初稿
误记为保留，Phase 601/ADR-0570 已修正并同步实现。）

Harmony 原实现：COPY/GROUP/UNGROUP/FLIP/LOCK 后保留选区，
GROUP/UNGROUP 还 `selectElementIds` 重选成员/新组——五处终态
与原版相反。

## 决策

1. COPY：`copySelectedToClipboard` 返回 true →
   `clearSelectionWithRegisterReset()`（失败路径不清，等价
   `cg2Var != 0` 条件）。
2. GROUP：`createOriginalGroup` 成功分支去掉
   `selectElementIds` 重选 → `clearSelectionWithRegisterReset()`。
3. UNGROUP：同上，去掉成员重选 → 清空。
4. FLIP_H/V：`flipSelected` 尾部 `updateSelectionOverlay` →
   `clearSelectionWithRegisterReset()`。
5. LOCK/UNLOCK：`setSelectedPositionLocked` 尾部同上。
6. DUPLICATE 不动：`pasteClipboard` 内部 `selectElementIds`
   重选粘贴副本，已等价 `lg2.b` → `e()`。

## 偏差（fail-closed 记录）

1. 原版 `fvbVar.a()` 同时清 `m`（绘制点）与 `n`（deselect
   快照）；Harmony `clearSelectionWithRegisterReset` 一并重置
   样式寄存器（等价终态，无用户可见差异）。
2. 原版 GROUP/UNGROUP 清空后，用户需重新点选新组——Harmony
   同步执行此语义；若后续需要"组后保持选中"的偏好，属新增
   行为而非移植。
3. 原版 COPY 清空与菜单关闭同时发生；Harmony ArkUI 菜单随
   覆盖层隐藏同步消失，无独立关闭通道。

## 验证

- `docs/migration/replays/d02-original-menu-action-clears-selection.mjs`
  18 项断言（五处清空 + DELETE/CUT 回归 + STYLE/SEND_* 保留 +
  清/留映射模型）。
- 证据：`docs/migration/evidence/original-menu-action-clears-selection-2026-09-23.md`。
