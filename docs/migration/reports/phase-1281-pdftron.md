# Phase 1281 报告 — PDFTron PDFNet

## 完成内容

- `com/pdftron`（27 JNI stub→`libPDFNetC.so`）：
  PDFNet/PDFDoc/Page/PDFViewCtrl/PDFDraw/Convert+
  `Annot`（native GetRect/GetType/IsValid 批注）+
  annots/Link+Highlights+Stamper+TextExtractor/
  TextSearchResult+sdf/Obj —— PDF 导入/渲染/批注/
  文本提取/导出商业原生 SDK。

## 产出

- evidence `phase-1281-pdftron.md`
- fixture `d02-pdftron.mjs`（10/10）
- ADR-1225（fail-closed）
