# ADR-1267：原版↔Harmony 覆盖矩阵（里程碑）

## 状态

已接受（Phase 1323，里程碑）。

## 决策

笔记核心 100% 覆盖（编辑/CRDT/同步/持久化/导入导出/
备份/卡片/录音/渲染/识别抽象）；平台依赖 fail-closed
或降级（OAuth/IAP/转写/MyScript/分析/360-video）。

## 理由

Phase 1200–1322 普查 + Harmony `ets/`（291 文件）核对：
- **保真**：CRDT 线格式+`exc.A0` 排序+FlatBuffer 信封、
  `.note` 导入导出、Room→RdbStore、widget→Form、录音、
  GLMath 原生、PenKit 预测。
- **fail-closed/降级**：billing、OAuth、live-transcription、
  MyScript 引擎（RecognitionProvider 抽象）、分析 SDK、
  360-video、PDFTron→PDFKit、ReLinker→hilog。

## 后果

迁移语义全景确立 —— 核心保真、平台边界清晰；后续
Phase 聚焦缺口细化/平台等价物/逐 op 一致性验证。
