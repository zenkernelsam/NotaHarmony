# Phase 705：原版 text_box_paper 文档默认设置 fail-closed 登记

继续 `feature_settings__*` 扫描：`document_defaults` 区内
`text_box_paper`（新建文本框纸张背景默认）为未登记项。JADX
审计后登记 fail-closed（ADR-0654）。

## 原版证据

- `z22` case ~10 `document_defaults` 区标题 + case 21
  `text_box_paper` 行（同区含已覆盖的 `template`）。
- `paper` 为 TEXT 块 LWW register：`cie`（`TextBlockImpl`）
  `getPaper()Lcom/…/flatbuffers/Paper` + `paperRegister`。

## Harmony 现状

**数据+渲染已完整**（无需改代码）：

- `TextBlockElement.paper?: PagePaperBackground | null`；
- CreateBlock：field 15 `decodeOriginalPaper`、TEXT-only 校验、
  `create_text_paper` 列、`cloneOriginalPaper` 应用；
- `Canvas2DTextRenderer:496` 渲染消费 `element.paper`——同步/
  导入的显式纸张文本块正确呈现。

**登记边界**：

- `text_box_paper` 偏好项不实现——新文本 draft 固定
  `paper: null`（无独立纸、随页纸），等价原版默认设置。

## 产物

- `docs/migration/adr/ADR-0654-original-text-box-paper-failclosed.md`
- `docs/migration/evidence/original-text-box-paper-jadx-2026-09-24.md`
- `docs/migration/replays/d05-original-text-box-paper-fail-closed.mjs`
  （8 断言：原版证据 + Harmony 数据/渲染面 + 边界）

## 验证

- 专项 8/8；全套件重跑通过后记录于修复总纲；双 HAP 0 错误。
