# Phase 1325 报告 — 算法保真度

## 完成内容

- 抽查 `core/algorithm` 对照原版 defpackage 基线：
  `ForceSmoother`（`ws4` 8ms 平滑窗+`dr4` 0.15 单点
  限幅，时间加权 EMA+delta 钳制，内联引用原版类）；
  `ms1`=ClosedRange\<Float\> 区间工具；`CubicFitter`/
  `PencilSplatGenerator`/`ShapeDetector`/`WidthOutline
  Builder` 各自对应原版（sqh/xaa/b90/w4a）—— 算法
  参数/公式逐方法保真移植。

## 产出

- evidence `phase-1325-algorithm-fidelity.md`
- fixture `d02-algorithm-fidelity.mjs`（10/10）
- ADR-1269
