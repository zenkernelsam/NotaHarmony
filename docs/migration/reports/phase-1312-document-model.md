# Phase 1312 报告 — 文档模型覆盖

## 完成内容

- Harmony `core/model`（31 文件）= 完整文档模型：
  元素块（Image/Math/Text/Shape/Stroke/Brush/Asset)、
  页面（Background/CoordinateSpace/ElementOrder/Paper
  Settings/PaperColor/DefaultTemplate/TemplatePicker)、
  `Original*` 策略（NoteTitle/NoteMetadata/SnapGuides/
  GroupSelection/ImageCrop/ImageInsertPlan/MathInsert
  Plan/HandwritingLanguage)、形状识别（Shape
  Recognition/ShapeHold*) —— 数据模型层完备+原版
  保真移植。

## 产出

- evidence `phase-1312-document-model.md`
- fixture `d02-document-model.mjs`（10/10）
- ADR-1256
