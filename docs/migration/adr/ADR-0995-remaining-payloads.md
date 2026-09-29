# ADR-0995 — 剩余操作载荷（录音/评论/复选/peer/瞬态/资产）

## 状态

accepted（文档+fixture，无源改动）——**32/32 载荷完备**

## 原版契约（`decompiled_1.0.3` 实证）

- `yn2`/`ke8` 录音：{recording:akb, 时间区间, name,
  segmentation:th7, zIndex}（ke8 无时间字段）。
- `tl2`/`ud8` 评论：{anchor,text[,resolved]}。
- `mqf` UpdateCheckbox{textField,location,isChecked}
  承接 he8.isChecked 废弃。
- `yda` PeerInteraction = 协同光标 op；
  `tdf` TransientInteractionEnded{interactionId}；
  `ra0` AssetCloudPersisted{assetHash}。

## Harmony 决策

- 字段全保留；peer/transient 为协同瞬态 op——无后端
  时 fail-closed 记录不执行；AssetCloudPersisted 仅记录。

## Parity 状态

等价（协同语义单机降级）。

## 验证

- `d02-remaining-payloads.mjs`：12/12 通过。
