# 原版 text_box_paper 设置与 TEXT paper register — JADX 证据（2026-09-24，Phase 705）

## 设置面

- `feature_settings__document_defaults` = "Document defaults"
  （`z22.java` case ~10，section header 样式 `are.I`）；
- `feature_settings__text_box_paper` = "Text box paper"
  （`z22.java` case 21，与 case ~20 `template` 同区）——
  新建文本框的纸张背景默认项。

## TEXT paper 是 LWW register

- `cie.java:9` 元数据：`getPaper()Lcom/gingerlabs/notability/core/
  flatbuffers/Paper`；`cie.java:147`：`TextBlockImpl` 含
  `paperRegister` + `resizesWidthToFitTextRegister`；
- `bie.java:68`：`new cie(this.d.a(), this.g.a(), this.e.a(),
  this.f.a())`——builder 组装 paper register；
- `l5d`：`getPaperRegister()…Register$Builder` 引用。

## Harmony 数据+渲染面（已对齐）

- `ElementTypes.ets`：`TextBlockElement.paper?: PagePaperBackground |
  null`（BlockCommon 保留域之一）；
- `OriginalCreateBlockOperation.ets`：
  - `:156` `paperTable = table.readTable(15)`；
  - `:203` `decodeOriginalPaper`；
  - `:225` `blockType !== TEXT && paper !== null` 拒绝；
  - `:378` `create_text_paper` 列（JSON）；
  - `:455` `cloneOriginalPaper(payload.paper)` 应用；
  - `:710-711` 读回校验。
- `Canvas2DTextRenderer.ets:496`：`element.paper === undefined ?
  null : element.paper`——渲染消费。

## 未对齐面（登记边界）

- `text_box_paper` 偏好项：Harmony `EditorSettingsStore` 无此键，
  设置页无此行；`NoteCanvasView.ets:9367` 新文本 draft
  `element.paper = null`——确定的默认（无独立纸张，随页纸）。

## 结论

TEXT paper 的 CRDT 数据面 + 渲染消费已完整；仅本地偏好项缺失
（默认 null 等价原版默认），按 ADR-0654 登记 fail-closed。
