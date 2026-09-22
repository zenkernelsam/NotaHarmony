# Phase 605 — LOCK/UNLOCK 单元素空切换仍清选（dhb case18/19）

- 日期：2026-09-23
- 结果：已实现对齐（一处 fail-closed）
- 证据：`docs/migration/evidence/original-lock-clears-noop-single-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0574-original-lock-clears-noop-single.md`
- Replay：`d02-original-lock-clears-noop-single.mjs`（8 项断言）

## 背景

原版 LOCK/UNLOCK（dhb case18/19）：

- **itc 单元素**：块（oy0=hp5 图片/xhe 文本/r08）`u5j.n(!t())`，
  形状（n5d）`u5j.x(!t())`，笔画等 `objX=null`；
  **`fvb.a()` 无条件清选**——无实际锁切换也清。
- **多选**：`xsc.k` 只统计形状（无非 null）；`vz6` 只翻转
  `t() != !allLocked` 的形状；翻转集非空才 `fvb.a()`。

Harmony 缺口：空 diff 一律早退——单笔画（菜单显示 LOCK）点击后
选区保留，与 itc 无条件清选不符。

## 实现

`setSelectedPositionLocked` 空 diff 早退处：

- 单元素选区（无组、五类合计==1）→ 补
  `clearSelectionWithRegisterReset()`；
- 多选/组空 diff → 维持 return（`arrayList9.isEmpty()` 等价）。
- 四类"已在目标态跳过"过滤保持（`t() != z15` 收集语义）。

## 验证

- Replay `d02-original-lock-clears-noop-single.mjs`：8/8。
- 全量 Desktop Replay 全绿。
- `note@default` / `note@ohosTest` HAP 构建通过。

## 遗留

- `wsc` 空载荷内部行为、`esc` 菜单可见性对单笔画的判定未解码
  （fail-closed 记录于 ADR-0574）。
