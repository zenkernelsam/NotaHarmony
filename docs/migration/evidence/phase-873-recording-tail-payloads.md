# Phase 873 证据 — 录音/尾部 op payload 登记（类型 1,2,5,6,27–31）

## 目的

登记剩余 `haa` 类型的 payload 表——录音（5/6）、元数据（1/2）、
PDF 字段（27）、复选框（28）、对端交互（29）、批注（30/31）。
至此 31 个非 NONE payload 全部完成字段级登记。

## 原版证据（`decompiled_1.0.3/sources/defpackage`）

### zq9 映射与字段图

| 类型 | 表 | 字段 |
|------|----|------|
| SET_METADATA(1) | l2d (8f) | f0=z2d、f1=m2d、f2=z2d、f3=Boolean、f5=String、f6=Float、f7=tv6、f8=dz0 |
| ASSET_CLOUD_PERSISTED(2) | ra0 (1f) | f0=ua0 资产 |
| CREATE_RECORDING(5) | yn2 (6f) | f0=akb、f1=long、f2=String 名称、f3=long、f4=ukb 段、f5=tmf |
| MODIFY_RECORDING(6) | ke8 (4f) | f0=qo5 目标、f1=String 名称、f2=ukb 段向量+Integer、f3=tmf |
| MODIFY_PDF_FIELD(27) | ee8 (5f) | f0=ua0 资产、f1=String fieldKey、f2=ww9、f3=String、f4=Boolean |
| UPDATE_CHECKBOX(28) | mqf (3f) | f0=qo5、f1=cxc 位置、f2=boolean 勾选态 |
| PEER_INTERACTION(29) | yda (5f) | fqa@f0、qo5 向量@f3、u76@f4、qqe@f5、boolean@f6 |
| CREATE_COMMENT(30) | tl2 (2f) | f0=im、f2=String |
| MODIFY_COMMENT(31) | ud8 (4f) | f0=qo5、f1=hd1、f2=z2d、f3=z1d |

### 语义锚点

- `ke8` 三个 setter 对应录音三寄存器：名称（String）、
  分段（ukb）、z_index（Integer）—— 与物化层 winner 寄存器
  模型（866）一致。
- `mqf` = {目标块 qo5, 复选框位置 cxc, 勾选 boolean} ——
  最小状态更新。
- `l2d` SET_METADATA = 笔记级 setter 簇（标题 z2d、背景 m2d、
  tv6/dz0 等）。
- `ra0` = 仅资产引用（云端持久化回执型 op）。

## Harmony 侧（`note/src/main/ets/data`）

- `OriginalCreateRecordingPayloadEncoder` +
  `OriginalRecordingOperation`/`Persistence`/`Store` ——
  name/segments/z_index 三 winner 列与 ke8 setter 对应。
- `OriginalSetMetadataOperation`/`PayloadEncoder`（l2d）。
- `OriginalAssetMetadata`（ra0 资产回执）。
- `OriginalModifyPdfFieldOperation`（ee8）。
- `OriginalLocalCheckboxMutation`（mqf 勾选）。
- `OriginalCommentOperation`（tl2/ud8 批注）。
- `OriginalPeerInteractionOperation`（yda 对端交互）。

## 结论

`haa` 全部 31 个非 NONE payload 类型完成字段级登记闭环
（859 判别 + 856/857 容量/校验 + 867–873 逐字段图）。
Harmony 侧各 op 均有编码器/应用器或明确登记。纯文档+fixture。
