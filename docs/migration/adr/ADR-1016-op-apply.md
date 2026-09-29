# ADR-1016：op-apply = 类型分发 + 实体表链

## 状态

已接受（Phase 1072）。

## 决策

Harmony 文档级 op-apply 按 `v69`：op-type switch →
每实体引用按 `t()/u()/s()/n()/k()/v()` 类别表链查找 →
类型化 `X.d(op,payload)`；`positionLocked` 走物化快照分支。

## 依据

`v69` MODIFY_POSITIONS 路由 + 六类别实体表 + `xhe`
特例 + "Inconsistent logic" 防御遥测。

## 后果

Harmony 按类别分实体表；opId 定位 + 类型化 apply。
