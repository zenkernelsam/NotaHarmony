# ADR-1210：Compose LayoutNode/DrawScope

## 状态

已接受（Phase 1266）。

## 决策

`ry8`/`dt7`/`hw6`/`jw6` 布局/绘制节点 → Harmony
`@Component`+`Canvas`/`onDraw` 回调。

## 理由

`ry8`=LayoutNode（`dt7` NodeCoordinator+`hw6`
MeasureResult）；`jw6`=DrawScope（`xd1` 委托+`lo3`
编辑器 ref+drawCircle/Line/dpToPx）—— Compose 布局/
绘制内部；vle 绑进绘制域。

## 后果

Harmony 布局/绘制 = 组件+Canvas onDraw —— 语义保真。
