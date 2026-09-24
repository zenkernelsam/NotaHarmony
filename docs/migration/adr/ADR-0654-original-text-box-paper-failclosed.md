# ADR-0654 「Text box paper」文档默认设置 fail-closed 登记

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：705
- 接续：ADR-0653（media_object_corners fail-closed）、ADR-0014
  （CreateBlock 公共 register 域）、ADR-0225（共享纸张设置）
- 证据：`docs/migration/evidence/original-text-box-paper-jadx-2026-09-24.md`

## 背景

原版设置页 "Document defaults" 区（`z22.java` case ~10 标题
`feature_settings__document_defaults`）内含 `feature_settings__
text_box_paper`（"Text box paper"，case 21）——新建文本框纸张
背景默认项。

`paper` 是 TEXT 块的 LWW register：`cie.java`（`TextBlockImpl`）
元数据 `getPaper()Lcom/…/flatbuffers/Paper` + `paperRegister`；
`bie.java` builder；`l5d` builder 引用。

Harmony 现状（数据+渲染已对齐）：

- `ElementTypes.ets`：`TextBlockElement.paper?: PagePaperBackground |
  null`；
- `OriginalCreateBlockOperation.ets`：field 15 `paperTable` 解码
  （`decodeOriginalPaper`）、`blockType !== TEXT && paper !== null`
  拒绝、`create_text_paper` 列持久化、`cloneOriginalPaper` 应用；
- `Canvas2DTextRenderer.ets:496`：渲染消费 `element.paper`——
  显式纸张的文本框按其纸张呈现。

## 决定

1. **不实现 `text_box_paper` 偏好项**：Harmony 新文本框固定
   `paper: null`——无独立纸张背景（随页面纸）——为确定的默认
   行为，等价原版默认设置。
2. **数据/渲染面不动**：外部同步/导入携带 `paper` 的文本块，
   Harmony 忠实存储、渲染与回写；仅本地创建种子固定 null。

## 后果

- 原版默认体验与 Harmony 完全一致；
- 原版用户改过 text box paper 的笔记，文本块 paper 寄存器数据
  无损往返，Harmony 也正确渲染其纸张；
- 若将来补偏好项，仅需 seed 一处（新建文本 draft），数据面
  无需变更。
