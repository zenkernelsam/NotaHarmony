# ADR-1155：vle 是 Compose Modifier.Node

## 状态

已接受（Phase 1211）。

## 决策

`vle extends n73`（DelegatingNode→od8 Modifier.Node）
→ Harmony `CustomComponent`/`@Component` 生命周期
（`aboutToAppear`/`aboutToDisappear` 对齐 `Y0`/`Z0`）
+ 显式子组件树（对齐 `g1` 委派）。

## 理由

`od8` = Modifier.Node 基类（`Y0`/`Z0`/`g1` + attach 守卫
+ `ModifierNodeDetachedCancellationException`）；
`n73` = DelegatingNode（`g1(j73)`/`ty8.e` 位掩码）；
`vle.Y0` 注册 `joe.m` + 挂 `bq4`、`Z0` 清理。

## 后果

Harmony 编辑器 = 组件生命周期 + 显式子节点持有 —
与 Compose Modifier.Node 委托树语义等价。
