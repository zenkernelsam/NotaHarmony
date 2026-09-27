# ADR-0817 — 录音/尾部 op payload 登记（31 类型闭环）

## 状态

accepted（文档+fixture，无源改动；Harmony 侧各 op 已覆盖或登记）

## 原版契约（`decompiled_1.0.3`）

- `yn2` CREATE_RECORDING：akb id/long/String 名称/long/
  ukb 段向量/tmf；`ke8` MODIFY_RECORDING：qo5 目标 +
  名称/段/z_index setter —— 对应三 winner 寄存器。
- `mqf` UPDATE_CHECKBOX：{qo5 块, cxc 位置, boolean 勾选}。
- `ee8` MODIFY_PDF_FIELD：ua0 资产 + fieldKey + ww9/String/
  Boolean。
- `tl2`/`ud8`：im+String / qo5+hd1+z2d+z1d 批注对。
- `l2d` SET_METADATA：z2d×2/m2d/Boolean/String/Float/tv6/dz0
  笔记级 setter 簇；`ra0` = 单 ua0 资产回执。
- `yda` PEER_INTERACTION：fqa/qo5 向量/u76/qqe/boolean。

## Harmony 决策

Create/RecordingOperation（name/segments/z_index 三 winner 列）、
SetMetadata、AssetMetadata、ModifyPdfField、LocalCheckbox、
Comment、PeerInteraction 各 op 层齐备。

## Parity 状态

等价/已登记。至此 `haa` 31 个非 NONE payload 字段级登记闭环。

## 验证

- `d02-recording-tail-payloads.mjs`：40/40 通过。
- 全量 Replay 与双 HAP 构建见 Phase 873 提交。
