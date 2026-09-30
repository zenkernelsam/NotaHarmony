# ADR-1277：激光笔 + 分组 op

## 状态

已接受（Phase 1334）。

## 决策

激光笔 = 瞬态轨迹（500ms 延迟+31×16ms 渐隐，对照
`zt6`/`yt6`）；分组 op = 层级+部分橡皮规划。

## 理由

`OriginalLaserPointer` = 瞬态渲染状态机（pointerPoint+
alpha，不落文档）：按下画轨迹，抬手 `yt6` 协程先等
500ms 再以 31 帧×16ms 衰减 alpha 后 `zt6.i()` 清空 —
— 对照原版。分组 op（`GroupLayering`/`MutationOpCodec`/
`PartialEraseGroupPlanner`/`ShapeGroupOperation`）。

## 后果

激光笔瞬态渐隐+分组 op 语义与原版一致 —— 功能保真。
