# Phase 778 — 原版 1.4.2 钢笔增强面登记

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-778-original-pen-enhancements.md`
ADR：`ADR-0722-original-pen-enhancements.md`
Replay：`d02-original-pen-enhancements.mjs`（8/8）

## 本阶段做了什么

登记 1.4.2 相对 1.0.3 的钢笔工具增强面：书法笔尖模型、
笔刷样式本地化标签、防抖开关，以及 ToolStateEntity 的
相应列差。

## 发现

- 笔尖密封族 `qx5`：`px5`=Standard 单例、`ox5`=
  CalligraphyNib(nibAngle, nibFlatness)；默认 angle=π/2、
  flatness=0；`jmc.b()` 输出书法笔画几何。
- ToolStateEntity 精确列差：style INTEGER→TEXT + 新增
  nibAngle/nibFlatness/stabilization（Phase 776 三列之外）。
- 八条新键：calligraphy/angle/flatness + brush_style_{fixed,
  variable,dashed,dotted} + stabilization——1.0.3 全缺席。
- `ij1` 渲染防抖选项行；`svi` SELECT 枚举 18 列全读。
- Harmony 已具 DASH/DOT/MONO/TAPER 样式（1.0.3 对齐），
  无书法笔尖/防抖概念。

## 分类

- 书法笔尖 + 防抖：版本差·本地候选（回移评审待定）。
- style 序列化迁移：原版内部实现，无需对应。

## 验收

- Replay 8/8 绿；全量套件与双 HAP 随本阶段执行。
- 三项跟踪文档已更新。
