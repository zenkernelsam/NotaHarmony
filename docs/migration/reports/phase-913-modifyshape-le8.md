# Phase 913 报告 — `le8`=ModifyShape 17 槽实名

## 范围

形状修改 op 载荷实名（CreateShape 对偶）。纯审计。

## 原版发现

- `le8` = ModifyShape：17 槽全实名；qo5[] 多目标 +
  setter 包装修改语义；定义判别子+子表双字段保留。
- 差异确认：无 smartHighlight/force；inkEffects
  为 tmf ULong。

## Harmony 核对

编码对齐；setter 包装通则二次确认。

## 产出

- 证据：`phase-913-modifyshape-le8.md`
- Fixture：`d02-modifyshape-le8.mjs`（20/20）
- ADR-0857；全量 Replay 786 文件绿。
