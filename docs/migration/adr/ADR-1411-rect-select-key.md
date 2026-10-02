# ADR-1411：Ctrl+Shift+T 矩形选区复用拖拽矩形命中核

## 状态

已接受（Phase 1476）。

## 背景

原版 `f2.java:230-238`：Ctrl+Shift+T 以视口中心构建 240×120 画布
矩形，`ome.a()` 清选后向 `ome.g` 状态槽发布 `u64(sbe)` 矩形选区
请求；消费端 `r3b.c(sbe, msf)` → `p3b` 协程做矩形相交命中——与
拖拽矩形完成路径（`ch1.java:55-68` `z3` 支）共用同一 `u64` 通道。

## 决策

不实现 `ome.g`/`ptg` 异步请求槽。键盘支直接同步执行
`beginSelection(RECTANGLE)` + `updateSelection(对角点)` +
`finalizeSelection(全元素集, strokeHit)`——复用拖拽矩形完成的
同一命中核（`rectIntersects`/`selectionPath`），保证两类矩形
选区入口行为同构。

## 依据

- 原版两入口（拖拽完成 `z3` 支 / 键盘 T 支）本就共用同一请求
  通道与消费核——Harmony 复用同一 finalize 管线即通道等价；
- 单 Page 内异步槽无并发收益，同步直调语义等价；
- 空命中 → `deselect()` + 隐藏覆盖层，等价于原版空 `msf` 结果。

## 后果

- 键盘与手势矩形选区命中规则永远一致（同一 `finalizeSelection`）；
- `bd8.U.r`/`u7b.g` 两派生旗均恒近似（登记差异，见 evidence）；
- DOWN 消费不动作与原版一致。
