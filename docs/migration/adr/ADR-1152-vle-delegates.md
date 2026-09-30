# ADR-1152：vle 委托架构（od8 子组件树）

## 状态

已接受（Phase 1208）。

## 决策

`vle` facade → `od8`/`n73` 子 ViewModel（`bq4` 语义/
选择、`ol3`+`ame`/`pl3` 指针输入、`u8e` Density 输入）
+ `xp4` Modifier.Node 树遍历 → Harmony `@Observed`
服务分组 + `componentUtils` 树查找。

## 理由

`bq4 extends n73 implements mvc,o65,q52,sn9` 承接 vle
iface；`ame implements pl3` 5-lambda 指针回调；
`xp4` `instanceof rd8` 遍历派发 —— 组件按能力
iface 组合的 Modifier.Node 树。

## 后果

Harmony 编辑器 = 能力分组服务 + 组件树派发 —
保留原版"按 iface 组合"结构。
