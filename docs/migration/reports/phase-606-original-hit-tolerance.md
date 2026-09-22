# Phase 606 — 元素命中两程 ±5 容差（fu1.e）

- 日期：2026-09-23
- 结果：已实现对齐
- 证据：`docs/migration/evidence/original-hit-tolerance-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0575-original-hit-tolerance.md`
- Replay：`d02-original-hit-tolerance.mjs`（13 项断言）

## 背景

原版 `fu1.e` 是所有点按探测的统一入口：先精确点查询，落空再以
±5 矩形 + 半径 5 查询圆复测，取 z 序最上；容差为**世界/page 单位**，
`fu1.j` 按元素缩放归一（`半径/maxScale`）后在元素本地判定
（块半长 +fB、形状描边带 + 查询圆、笔带宽 + 查询圆）。

Harmony `topmostPageElementIdAt` 只测精确点——元素边缘 5 单位内
的点按在原版能命中、Harmony 判 miss（清选/落空）。

## 实现

- `topmostPageElementIdAt` → `hitOrderedElementIdAt` 两程
  （exact→tol5）；z 序遍历不变。
- 容差=世界单位（`fu1.j` 缩放归一）：块 `expandLocalBounds(bounds,
  worldTol, transform)` 以 `worldTol/maxScale` 转本地后四边扩张；笔
  `brushWidth·wf·scale/2 + worldTol`；形 `strokeWidth·scale/2 +
  worldTol`。`hitStrokeAtPoint`/`pointHitsShape` 增默认 0 的
  `worldTolerance` 参数。
- `tapeIdsAtPoint`：精确收集空 → 两程顶层是 tape 回退单例
  （`xtc.b` setX1 空回退）。
- 所有 `topmostPageElementIdAt` 消费方自动继承两程语义。

## 验证

- Replay `d02-original-hit-tolerance.mjs`：13/13。
- `d02-original-selection-tap-clear`、`d02-original-tape-tap-reveal`
  随签名演进更新后通过。
- 全量 Desktop Replay 全绿；`note@default`/`note@ohosTest` 通过。

## 遗留

- 原版第二程先 ±5 矩形宽相；Harmony 直接全元素精判（结果等价）。
- 修正记录：初版实现误将容差 5 作元素本地单位（笔/形半径乘 scale
  前加 tol）；`fu1.j`（fu1.java:244）的缩放归一证据确认 ±5 为
  世界/page 单位，本提交已修正为世界容差（块 `worldTol/scale`、
  笔/形世界半径直接 +5）。
