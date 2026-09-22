# Phase 608 — 区域选区剔除 positionLocked 元素（fu1.b → jrh.a）

- 日期：2026-09-23
- 结果：已实现对齐
- 证据：`docs/migration/evidence/original-lock-region-filter-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0577-original-lock-region-filter.md`
- Replay：`d02-original-lock-region-filter.mjs`（9 项断言）

## 背景

原版矩形/套索选区完成走 `f(uh5) → b(锁剔除) → c(组扩展)`：
`fu1.b` 在 POSITION_LOCKED（PRODUCTION 默认开）下剔除
`jrh.a` 为真的元素——块 `t()`、可锁形状 `cih.a && t()`；
笔迹永不剔除；点按路径不过滤（锁定元素可点选解锁）。

Harmony 旧实现 `finalizeSelection` 把锁定元素照常圈入——
锁定元素可被框选/拖动，与原版钉住不动语义不符。

## 实现

- `SelectionTool.finalizeSelection`：形状/文本/图片/数学命中循环
  前置 `positionLocked === true → continue`；笔迹不剔；
  剔除位于 `resolveOriginalGroupSelection` 之前（f→b→c 次序）。
- 组扩展对锁定成员不再二次过滤（`fu1.c` 无锁检查，行为一致）。
- 点按/揭示路径不变——锁定元素仍可点选解锁。
- `SelectionTool.test.ets` 四处预期同步为原版语义。

## 验证

- Replay `d02-original-lock-region-filter.mjs`：9/9。
- 全量 Desktop Replay 全绿；`note@default`/`note@ohosTest` 通过。

## 遗留

- `cih.a`（`!n5d.y` 可锁门控）简化为 `positionLocked`——不可锁
  形状 `t()` 必假，等价；异常置锁时 Harmony fail-safe 剔除。
- `ac4.Q` 远程开关未建模（按默认开）。
