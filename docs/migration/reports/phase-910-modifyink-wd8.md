# Phase 910 报告 — `wd8`=ModifyInk 19 字段实名

## 范围

墨迹修改 op 载荷实名（CreateInk 对偶）。纯审计。

## 原版发现

- `wd8` = ModifyInk：19 字段全实名，首字段 inks 目标
  qo5 向量；rotation/scale/fillColor 用 setter 包装；
  无 tool 字段。
- 创建/修改二元性确认：裸值 vs 包装器为协议通则。

## Harmony 核对

编码槽位对齐；setter 包装契约对齐 ie8 模式。

## 产出

- 证据：`phase-910-modifyink-wd8.md`
- Fixture：`d02-modifyink-wd8.mjs`（23/23）
- ADR-0854；全量 Replay 783 文件绿。
