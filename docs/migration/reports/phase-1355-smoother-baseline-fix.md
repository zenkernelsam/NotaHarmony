# Phase 1355 报告 — ForceSmoother 基线更正

## 完成内容

- **更正 Phase 1325**：`hr4`/`dr4` 实为文本标题样式
  枚举（`fr4("Heading3",3,true,18.0f)`），非笔画平滑器；
  原版真实平滑器未在混淆名定位。Harmony `ForceSmoother`
  （8ms EMA+0.15 钳制）实现正确，基线引用更正。
- **三大算法基线更正完成**：平滑（1325→1355）、拟合
  （1326→1354）、检测（1327→1352）误标均已修正。

## 产出

- evidence `phase-1355-smoother-baseline-fix.md`
- fixture `d02-smoother-baseline-fix.mjs`（10/10）
- ADR-1296
