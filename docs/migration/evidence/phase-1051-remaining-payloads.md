# Phase 1051 证据 — 录音/评论/复选/peer/瞬态载荷（31 载荷收尾）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 字段布局（toString 实名）

| 载荷 | 字段 |
|---|---|
| `yn2` CreateRecording | `{recording:akb, startTime, endTime, name, segmentation:th7, zIndex:tmf}` |
| `ke8` ModifyRecording | `{recording, name, segmentation, zIndex}` |
| `tl2` CreateComment | `{anchor, text}` |
| `ud8` ModifyComment | `{comment, anchor, text, resolved}` |
| `mqf` UpdateCheckbox | `{textField:qo5, location:cxc, isChecked}` |
| `yda` PeerInteraction | `{cursorPosition:fqa, selectedEntities, tool:u76, textSelection:qqe, recordingInProgress}` |
| `tdf` TransientInteractionEnded | `{interactionId}` |
| `ra0` AssetCloudPersisted | `{assetHash}` |

## 新类型

- `akb` = 录音资产（zjb RecordingAsset 包装源，Phase 996）。
- `th7` = segmentation 类型；`u76` = peer 工具枚举；
  `qqe` = textSelection 类型。

## 语义注记

- `UpdateCheckbox` 承接 `he8.isChecked` 废弃路径
  （Phase 1050 呼应）。
- `PeerInteraction` = 协同光标广播（cursor/selection/
  tool/recording 状态）——网络 op，不落本地语义。
- `AssetCloudPersisted` = 资产云端持久化回执 op
  （`assetHash` 标识），同步管线衔接（Phase 997-999）。

## Harmony 决策

- 全部字段保留；`PeerInteraction`/`TransientInteraction
  Ended` 为瞬态协同 op——Harmony 端建模但标记
  本地回放 no-op（无协同后端时 fail-closed）。
- `AssetCloudPersisted` 在单机构建中仅作记录。

## 产出

- fixture `d02-remaining-payloads.mjs`（12 断言）。
- ADR-0995；中文报告。**至此 32/32 操作载荷全部审计完毕。**
