# ADR-1186：gn3 编辑器 Node（双终态）

## 状态

已接受（Phase 1242）。

## 决策

`gn3` n73+4 iface Node+`mn3`→`nn3`/`ln3` 双终态 →
Harmony 组件节点+onTouch+双终态事件。

## 理由

`gn3`=抽象编辑器 Node（`mn3` start+`nn3`/`ln3` 双
终态，`m1`→`ln3`）+ 全指针生命周期 —— 手势 cancel
语义保真。

## 后果

Harmony 手势节点 = 组件+onTouch+双终态 —— cancel
语义保真。
