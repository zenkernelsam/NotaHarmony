# Phase 1334 证据 — 激光笔 + 分组 op

来源：`core/adaptation/OriginalLaserPointer.ets`+
`data/{OriginalGroupLayering,OriginalGroupMutationOpCodec,
OriginalGroupPayloadEncoder,OriginalPartialEraseGroupPlanner,
OriginalShapeGroupOperation}.ets`。

## `OriginalLaserPointer` = 瞬态渲染状态机

```
对照 zt6/xt6/yt6/du6/cu6（原版 laser pointer）：
  pointerPoint + pointerAlpha —— 瞬态（不落文档）
  按下画点（!showTail 轨迹）；抬手后 yt6 协程：
    先等 500ms → 31×16ms 逐帧衰减 alpha → zt6.i() 清空
  fade 恰好落在 alpha 字段
```

→ 激光笔 = 瞬态轨迹（不持久化）+ 抬手 500ms 延迟 +
31帧×16ms 渐隐 —— 对照原版 `zt6/yt6` 状态机。

## 分组 op 层

- `OriginalGroupLayering` —— 分组层级。
- `OriginalGroupMutationOpCodec`/`PayloadEncoder` ——
  分组 op 编解码。
- `OriginalPartialEraseGroupPlanner` —— 分组部分橡皮规划。
- `OriginalShapeGroupOperation` —— 形状分组 op。

## Harmony 决策

激光笔 = 瞬态 500ms+31×16ms 渐隐状态机（对照 `zt6/yt6`）；
分组 op = 层级+部分橡皮规划 —— 功能保真。

## 产出

- fixture `d02-laser-group.mjs`（10 断言）。
- ADR-1277；中文报告。
