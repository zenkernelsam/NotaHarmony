# ADR-1399: 锁定比选区缩放的逐成员 jv6 文本 16px 下限

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1464
- **关联**: evidence/phase-1464-member-text-floor.md（`guf.h`
  逐成员钳制代码证据）、ADR-1393（单文本 freeScale 地板，
  Phase 1459）

## 背景

`guf.h`（wtf 应用函数）对 map 内**每个成员独立**计算有效缩放：
jv6 文本成员逐轴钳到 `max(s, 16/(框尺寸·现有轴幅))`，非文本成员
直接乘请求比。P1459 只覆盖了 freeScale（lsf 单文本块）路径；
锁定比路径（isf/jsf 混合多选含文本块）缺失地板，文本可被压到
16px 以下。

## 决策

锁定比支在统一缩放应用后，调 `applySelectionTextFloor` 遍历全部
选中文本块做**逐成员分歧校正**：

- 每成员以 `dragBeforeTextBlocks` 会话前快照求 `floor_i`，校正
  `c_i = max(1, floor_i/s)`；
- 校正矩阵绕 resizeAnchor 共轭到壳旋转系
  （`T·R(θ)·diag·R(−θ)·T⁻¹`，θ=0 退化为轴对齐）；
- 校正仅作用于文本成员的 `transform`/`bounds`，其余成员不动；
- 校正发生在统一选区变换**之后**，因此是叠加在 state.transform
  上的成员级增量（这是与原版"同一次缩放函数内逐成员选比"的
  等价移植——Harmony 架构无逐成员缩放通道）。

## 等价性与边界

- 等比路径 s 为标量时 `c_i` 表达式与原版 `max(s, floor_i)` 的
  `floor_i/s` 等比校正**数学上完全一致**（等比变换下
  `T·R·diag(c,c)·R⁻¹·T⁻¹` = 绕锚 c 倍缩放）。
- 独立轴请求（sx≠sy 锁定比路径虽 s==s，但 freeScale 已另有支）
  逐轴 `c_i` 仍与原版逐轴 `max` 一致。
- 不覆盖 `guf.m`（utf 捏合）——捏合等比缩放原文无 16px 地板。
- 页界迁移 `a()` 仍 fail-closed（P1459 登记）。

## 后果

isf/jsf 含文本块的多选缩放到小于 16px 时，文本成员停在其各自
16px 地板（可分歧），与原版 `guf.h` 逐成员钳制一致。
