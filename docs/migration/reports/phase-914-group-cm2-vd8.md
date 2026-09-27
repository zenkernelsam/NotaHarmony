# Phase 914 报告 — `cm2`/`vd8` 分组 op 实名

## 范围

分组创建/修改 op 载荷实名（871 族收尾）。纯审计。

## 原版发现

- `cm2` = CreateGroup：仅 members qo5[]@0；零成员拒绝。
- `vd8` = ModifyGroup：group qo5@0 必填 + members@1。
- qo5 为 8B 内联结构向量元素（寻址公式实证）。

## Harmony 核对

编码对齐：结构向量 + 必填断言。

## 产出

- 证据：`phase-914-group-cm2-vd8.md`
- Fixture：`d02-group-cm2-vd8.mjs`（13/13）
- ADR-0858；全量 Replay 787 文件绿。
