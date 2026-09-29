# ADR-0934 — `lgf` 持久化 op 树 + 导出规范序

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `lgf` = 持久化 op 树节点（`{size, Object[]}`，嵌套
  lgf；`d`=EMPTY 单例；`f`=节点工厂；`a()`=递归 size；
  `b/c/d`=不可变更新/拼接）。
- `mia` = DFS 迭代器（rgf 帧栈+深度 J+耗尽标志 K）。
- 导出规范序 = **(qo5.timestamp, qo5.site) 升序**
  （k79(3)=mmf(ts) 主键，k79(4)=ymf(site) 次键，
  `ldj.G1`→`d02` 链式比较器）。

## Harmony 决策

等价语义：不可变 op 集合 + DFS 遍历 + (ts,site)
规范序；无持久树性能需求时可退化为不可变数组。

## Parity 状态

等价。

## 验证

- `d02-op-tree.mjs`：15/15 通过。
