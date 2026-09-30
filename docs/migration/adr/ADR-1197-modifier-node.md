# ADR-1197：od8 Modifier.Node 基座

## 状态

已接受（Phase 1253）。

## 决策

`od8` Modifier.Node（`I`/`L`/`K`+`M`/`N`/`P`/`J`+attach/
detach 守卫）→ Harmony 组件 Node+协程域+能力位。

## 理由

`od8`=`j73` 基：`I`=self/`L`=kind-mask/`K`=kind-set/
`M`/`N`=parent-child/`P`=LayoutNode/`J`=协程 scope +
`ModifierNodeDetachedCancellationException` detach-cancel
—— Modifier.Node 基座。

## 后果

Harmony 节点基座 = 组件 Node+协程+能力位 ——
基座语义保真。
