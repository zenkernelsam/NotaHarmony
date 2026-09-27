# Phase 873 报告 — 录音/尾部 op payload 登记（31 类型闭环）

## 范围

登记剩余 `haa` payload：l2d/ra0/yn2/ke8/ee8/mqf/yda/tl2/ud8
九表字段图；核对 Harmony 各 op 层。纯审计阶段，无源改动。

## 原版发现

- `ke8` 的 name/segments/z_index setter 精确对应物化层三个
  winner 寄存器（866 登记的 fqb 语义）。
- `mqf` = {qo5, cxc, boolean} 最小勾选更新；
  `s83`-式向量惯例延续到 `ke8`/`yn2`/`yda`（访问器+计数）。
- `l2d` SET_METADATA 为笔记级 setter 簇（含 m2d 背景）。

## Harmony 核对

录音三 winner 列、SetMetadata、PdfField、Checkbox、Comment、
PeerInteraction、AssetMetadata 层齐备。

## 产出

- 证据：`phase-873-recording-tail-payloads.md`
- Fixture：`d02-recording-tail-payloads.mjs`（40/40）
- ADR-0817；全量 Replay 与双 HAP 结果记录于提交。

## 里程碑

`haa` 全部 31 个非 NONE payload 类型字段级登记闭环
（859 判别 → 856/857 容量/校验 → 864–866 物化/寄存器 →
867–873 逐字段图）。
