# Phase 643 — 分享面板 PDF 行：整册逐页栅格化 PDF 导出

日期：2026-09-23。前置：Phase 641（分享面板）/ Phase 642（页栅格化）。

## 原版行为（decompiled_1.0.3）

- `s6d.PDF`：`ui_share__chip_pdf` + `atc` case4 图标，面板序第二位。
- `b7d`：`list.size()>1 ? PDF : LINK` —— 集合导出默认 PDF。
- `y59.a`：对页集合调 `b(s6d.PDF, listL0, ...)`；`y59.b` 未反编译。

## Harmony 改动

| 文件 | 改动 |
|------|------|
| `data/PagePdfExporter.ets`（新） | `buildPdf` 最小 PDF 1.4 组装器（Catalog/Pages/页三元组、DCTDecode JPEG、mm→pt MediaBox、xref/trailer）+ `exportPdf` picker 保存管线 + 页数/字节预算闸门 |
| `ui/editor/EditorToolbar.ets` | `onSharePdf` 回调；PDF 行 `supported=true`；`'pdf'` 派发 |
| `ui/editor/NotePage.ets` | `shareNoteAsPdf()`：pages 快照序逐页 `renderPageExport` ×2 → `packToData(image/jpeg q92)` → `PdfPageImage` → `exportPdf`；资源 finally 释放 |

## 登记差异（ADR-0610）

1. 上游编码不可见 → Harmony 纯栅格 PDF（无矢量/字体嵌入证据）。
2. 页范围选择（`v6d.l`）未实现，恒整册。
3. 多笔记合并导出无入口。
4. LINK 行仍 fail-closed。

## 验证

- fixture `d05-original-share-pdf.mjs` 24 断言绿；`d05-original-editor-share.mjs` 更新后 41 断言绿。
- 全量 Desktop Replay 528/528。
- `note@ohosTest`、`note@default` clean 构建通过；无新增 ArkTS error。
