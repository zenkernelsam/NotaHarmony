# ADR-1151：vle 绑入 Compose 节点树

## 状态

已接受（Phase 1207）。

## 决策

`vle.f(ry8 LayoutNode)` + `x0(jw6 DrawScope)` +
`r(mv6 LayoutCoordinates)` → Harmony `CustomComponent`/
`Canvas` 绘制上下文 + `componentUtils` 坐标。

## 理由

`ry8 extends dt7 implements l28,mv6,ow9`（LayoutNode）
+ `jw6{xd1 DrawScope 委托, lo3 J 编辑器回链}` +
`mv6` 坐标变换全集 —— 编辑器嵌进 Compose 节点树
由框架驱动绘制。

## 后果

Harmony 编辑器 = 自定义组件 + Canvas/绘制上下文
注入 —— 与 Compose LayoutNode 语义等价。
