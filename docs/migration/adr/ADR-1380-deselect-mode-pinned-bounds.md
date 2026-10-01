# ADR-1380: deselectMode 钉住选区界（isf.a/o 在点除中不收缩）

## 状态

已接受（2026-08，Phase 1445）

## 背景

Phase 1439-1444 逐层收口了选择菜单的装配、序、门控与分发；Phase 1445 审计 deselectMode（isf.h）的点除语义时发现一处真实渲染缺口。

原版（decompiled_1.4.2）`isf` 的选区轮廓 `o = hsm.b(a, f, m)` = 入模时的绘制域 `a` ∪ 组界——`mud` case7 点除变换只覆写 `g`/`i`/`m`/`n`（掩码 3775），`a`/`b`/`c`/`j` 保留，故**点除成员期间选区框不收缩**；`zf3` 的界内空点（`atf`=None）/界外取消（`wsf`=CancelDeselectMode）判定也用同一 `a`。Harmony 此前 `selectionRect` 恒为存活成员 union——每剔一个成员轮廓即收缩，且界外取消的判定域随收缩变小，与原版不符。

## 决策

1. `SelectionState` 增 `deselectBounds: Rect2D | null`——入模界快照（`enterDeselectMode(bounds)`），点除不改；`confirm`/`cancel`/`deselect`/`beginSelection`/`selectElementIds` 五路清零。
2. `updateSelectionOverlay` 尾段：deselectMode 且钉住界非空时以其替代成员 union 算 `selectionRect`（含 `pointInSelectionRect` 界外取消判定域一并钉住——与 `f5n.h(a,…)` 同域）。
3. `deselectElements` 增 `deselectMode` 门（`zf3` 仅 `h=true` 产 `ysf`，非模式调用拒为死路径兜底）。
4. `htd` case5 的 `j`（bpj 会话 UUID）守卫在 Harmony 模型中不可达——快照与模式同生共死（`selectElementIds`/`deselect` 皆清 `preDeselectSelection`），故不引入会话令牌；登记为等价映射。

## 后果

- deselectMode 下点除成员时选区框保持入模界；剔空仍 `deselect()`（mud→null / ome.m=null 语义）。
- 组内成员点按剔整组、界内空点无操作、界外取消恢复等已有语义不变（本 Phase 复核一致）。
- 确认/取消出口轮廓回成员 union（与 Harmony 既有 isf 轮廓惯例一致——原版 `o` 永续钉 `a` 属绘制域轮廓的基线适配差异，不在本 Phase 范围）。

## 验证

`d02-deselect-mode-pinned-bounds.mjs` 14/14；`d02-original-deselect-mode.mjs` 22/22；`d02-selection-deselect-isf-gate.mjs` 18/18；基线 1295/1295；双 HAP 构建通过。
