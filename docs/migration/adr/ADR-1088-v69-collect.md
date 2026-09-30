# ADR-1088：v69.y 受影响 id 批量收集

## 状态

已接受（Phase 1144）。

## 决策

- `v69.y(ops,set,u69)` = op→`u09` 受影响集：分类产
  `bl2` 页墓碑、`r09` 页 ref、`t09` id-list ref →
  `LinkedHashSet`。
- `v69.x` = `x82` 并行分区 suspend 收集（`w` 委托）。

## 依据

`bl2(op.l(),tz9,TRUE)` + `r09`/`t09` + `lia` op 缓冲 +
`u69` 分类 lambda。

## 后果

Harmony：ops→分类（页墓碑/页/容器）→`Set<u09>` 受影响
集，喂 `ba6.y` 解析。
