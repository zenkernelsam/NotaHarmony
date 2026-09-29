# Phase 990 报告 — `lgf` op 树 + 导出排序键

## 范围

lgf/mia/rgf/k79/ldj.G1。纯审计。

## 原版发现

- `lgf` = 文档模型的**持久化 op 树**（嵌套节点 +
  EMPTY 单例 + 不可变更新）。
- `mia` = DFS 迭代器（rgf 帧栈）。
- **导出规范序 = (timestamp, site)**：k79(3)/(4) =
  mmf(id.ts)+ymf(id.site)，ldj.G1→d02 链式比较。

## 产出

- 证据：`phase-990-op-tree-collection.md`
- Fixture：`d02-op-tree.mjs`（15/15）
- ADR-0934；全量 Replay 见本提交。
