# Phase 939 报告 — 尾批 op 表偏移钉死

## 范围

s83/tdf/je8/ge8/tl2/ud8 访问器→偏移。纯审计。

## 原版发现

- s83=DeleteEntities 四墓碑：qo5×2+cxc×2。
- tdf={interactionId,replacedByOp:qo5}。
- ge8=ModifyPage 4 字段；tl2/ud8 注释对——
  **ud8 锚固定 hd1（非多态）**，只能改 Canvas 锚。

## 产出

- 证据：`phase-939-op-offset-tail.md`
- Fixture：`d02-op-offset-tail.mjs`（17/17）
- ADR-0883；全量 Replay 812 文件绿。
