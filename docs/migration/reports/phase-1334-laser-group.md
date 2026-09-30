# Phase 1334 报告 — 激光笔 + 分组 op

## 完成内容

- `OriginalLaserPointer` = 瞬态渲染状态机（对照 `zt6`/
  `xt6`/`yt6`/`du6`/`cu6`）：pointerPoint+alpha 不落文档，
  抬手等 500ms 后 31帧×16ms 渐隐 → `zt6.i()` 清空；
  分组 op 层（`GroupLayering`/`MutationOpCodec`/
  `PartialEraseGroupPlanner`/`ShapeGroupOperation`）——
  激光笔瞬态+分组 op 保真。

## 产出

- evidence `phase-1334-laser-group.md`
- fixture `d02-laser-group.mjs`（10/10）
- ADR-1277
