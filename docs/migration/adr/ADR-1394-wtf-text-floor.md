# ADR-1394：wtf 文本块 16px 缩放下限 + 页框迁移 fail-closed

- 状态：已采纳
- Phase：1459

## 背景

`guf.h`（wtf 双轴缩放应用）含两处 Phase 1455 登记项：
`jv6` 文本 16px 下限与 `z=true` 页框迁移。本 Phase 补前者，
后者经解码后裁定 fail-closed。

## 决策

1. **16px 文本下限**（已实现）：`resizeFreeScale` 支逐轴
   `factor = max(请求, 16/(blockDim·existingScale))`；
   `existing` 取 `dragBeforeTextBlocks` 会话前 transform 轴幅。
   仅 freeScale（lsf 单文本块）支——`guf.h` 下限是逐成员的，
   多成员 isf 中仅文本成员被钳产生分歧缩放，Harmony 单矩阵
   变换无法逐成员分歧，故按 freeScale 门内（唯一单文本场景）
   实现，isf 成员分歧登记为差异。
2. **页框迁移 fail-closed**：`guf.a` = 提交时成员越页界迁移到
   绝对 Y 命中的邻页（`zq.n0` 页查找 + 坐标重写）。Harmony
   逐页编辑器模型（单页装载、页内 undo）不支持单事务跨页
   元素迁移——不强行实现，登记为结构性差异。
3. **utf 不加下限**：`guf.m` 无 jv6 支（逐成员 `existing*f`
   直乘），捏合等比缩放不钳制——与原版一致。

## 验证

- `d02-original-scale-session-wtf.mjs` 扩至 24 项
  （floor 表达式、会话前快照、freeScale 门内、可执行模型）。
