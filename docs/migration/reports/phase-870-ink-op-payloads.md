# Phase 870 报告 — 墨迹 op payload 登记

## 范围

登记 `haa` 15–17 墨迹三表（dm2/gd/wd8）字段模式；核对
Harmony 墨迹 op 层。纯审计阶段，无源改动。

## 原版发现

- `wd8` MODIFY_INK 连续 19 字段全图恢复：f0=qo5 目标向量、
  f5=t16 样式、f6=hu1 颜色、f7=Float 宽度、f12=yyd styleMap
  向量等。
- `dm2` CREATE_INK 19 槽（缺 f9）：cxc/hu1/mmf/ymf/fqa/qed。
- `gd` ADD_PATH_ELEMENTS：qo5 目标 + 路径元素向量。

## Harmony 核对

ModifyInk 写手 19 槽 vtable 字段锚点逐项一致；Create/AddPath/
InkPath/StyleMap 编码器全覆盖。

## 产出

- 证据：`phase-870-ink-op-payloads.md`
- Fixture：`d02-ink-op-payloads.mjs`（34/34）
- ADR-0814；全量 Replay 与双 HAP 结果记录于提交。
