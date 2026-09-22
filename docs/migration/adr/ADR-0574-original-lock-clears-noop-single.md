# ADR-0574 — LOCK/UNLOCK 单元素空切换仍清选（dhb case18/19）

- 状态：Accepted（一处 fail-closed）
- Phase 605；对齐 `dhb`/`xsc.k`/`n5d.t`/`oy0`（decompiled_1.0.3）。

## 背景

原版 LOCK/UNLOCK 菜单动作（dhb case18/19 合并实现）：

- **itc 单元素**：块实体（`oy0` = hp5 图片 / xhe 文本 / r08）走
  `u5j.n(!t())`；形状（`m4d`/`n5d` + `cih.a`）走 `u5j.x(!t())`；
  笔画等其余实体 `objX=null`。随后 `wsc` 协程 +
  **`fvb.a()` 无条件清选**——包括没有实际锁切换的情形。
- **多选**：`xsc.k` 仅统计形状（非 m4d → null → 无操作无清选）；
  `vz6` 只翻转 `t() != !allLocked` 的形状；`fvb.a()` 仅在
  翻转集非空时执行。

Harmony 缺口：`setSelectedPositionLocked` 空 diff 一律早退——
单笔画（菜单按 selectedCount===1 显示 LOCK）点击后选区保留，
与原版"itc 无条件清选"不符；而全形状多选已达标时空 diff
本应与原版一致保留选区（现状碰巧正确）。

## 决策

空 diff 早退处区分两类：

- 单元素选区（无组 + 五类合计==1，itc 等价）→
  `clearSelectionWithRegisterReset()`（fvb.a() 无条件语义）。
- 其余（多选/组）→ 保持 return（`arrayList9.isEmpty()` 语义）。

形状/文本/图片/数学的"已在目标态跳过"过滤不变，与原版
`t() != z15` 收集一致。

## 偏差（fail-closed）

- `wsc` 对 `objX=null` 的内部行为未解码到底，按无可观察副作用
  处理（除清选外）。
- `esc` 菜单可见性生产者未解码：原版单笔画是否显示 LOCK 不可证。
  Harmony 维持显示并将点击行为对齐为清选；若原版隐藏该项，
  本改动亦无害（菜单项行为与原处理器语义一致）。

## 验证

- `d02-original-lock-clears-noop-single.mjs`：8 断言
  （itc 条件、五类计数、无条件清选、多选 return 次序、
  目标态跳过过滤）。
- 全量 Desktop Replay 全绿；`note@default`/`note@ohosTest` 通过。
