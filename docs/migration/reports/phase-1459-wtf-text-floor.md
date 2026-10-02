# Phase 1459 修复报告 — wtf 文本块 16px 缩放下限

## 目标

补 `guf.h`（wtf 角柄双轴缩放应用）遗留的 `jv6` 文本 16px
显示下限；同时裁决同方法的 `z` 页框迁移支。

## 原版证据

- `guf.java:280-354`：文本成员 `pfgA.d/c`（框宽/高）×`hv6.b()`
  现有缩放 ≥16 为逐轴地板：`fD2=max(sx, 16/(w·ex))`、
  `fC2=max(sy, 16/(h·ey))`；非文本成员不钳制。
- `guf.m`（utf）无此支——等比捏合不钳制文本。
- `guf.a`（z=true 支）= 越页界成员跨页迁移（zq.n0 页查找 +
  坐标重写）。

## Harmony 实现

- `applySelectionResize` freeScale 支逐轴钳制：基准取
  `dragBeforeTextBlocks` 会话前快照（框尺寸+transform 轴幅），
  `scale ≥ 16/(dim·existing)`。
- isf 多成员逐成员分歧钳制无法以单矩阵表达——登记差异。
- 跨页迁移 fail-closed：逐页编辑器模型无跨页单事务设施，
  ADR-1394 登记。

## 验证

- `d02-original-scale-session-wtf.mjs` 扩至 24 项绿。
- 全量基线 + note@default + note@ohosTest 构建见提交说明。
