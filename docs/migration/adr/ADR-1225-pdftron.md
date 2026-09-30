# ADR-1225：PDFTron PDFNet

## 状态

已接受（Phase 1281）—— **fail-closed**。

## 决策

PDFTron → Harmony 无移植，fail-closed：渲染/批注→
系统 PDF 组件或自研 GL；文本提取→`pdf` 库；导出→
手写 PDF writer（`PagePdfExporter` 已存在）。

## 理由

`com/pdftron`（27 JNI stub→`libPDFNetC.so` 原生）：
PDFNet/PDFDoc/Annot(native GetType)/TextExtractor/
Stamper/Convert/sdf —— PDF 导入/渲染/批注/文本提取/
导出全原生商业 SDK —— Harmony 无法移植。

## 后果

Harmony PDF = 系统组件+手写 writer+`pdf` 库 —
— PDF 功能部分降级，原生 SDK fail-closed。
