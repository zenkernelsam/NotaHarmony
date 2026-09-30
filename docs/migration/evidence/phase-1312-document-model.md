# Phase 1312 证据 — Harmony `core/model` 文档模型

来源：`core/model/`（31 文件）。

## 文档模型覆盖

```
元素类型    ElementTypes/ImageBlockGeometry/MathBlock
            Geometry/TextBlockGeometry/ShapeGeometry/
            ShapeStrokeGeometry/StrokeTypes/BrushTypes/
            AssetTypes/NoteTypes/GeometryTypes
页面        PageBackgroundModel/PageCoordinateSpace/
            PageElementOrder/OriginalPaperSettings/
            OriginalPaperColor/OriginalDefaultTemplate/
            OriginalTemplatePickerState
原版策略    OriginalNoteMetadataPolicy/OriginalNoteTitle
            Policy/OriginalSnapGuides/OriginalGroupSelection/
            OriginalImageCropGeometry/OriginalImageInsert
            Plan/OriginalMathInsertPlan/OriginalHandwriting
            LanguagePolicy
形状识别    ShapeRecognition/ShapeHoldAdjustment/
            ShapeHoldLifecycle
Op         OpTypes（Phase 1308）
其他        BlockHitGeometry
```

`Original*` 前缀 = 原版行为保真移植（纸色/模板/吸附/
裁剪/插入计划/语言策略/元数据/标题策略）。

## 语义

Harmony 文档模型 = **元素块**（图/数学/文本/形状/
笔画）+ **页面**（背景/坐标/元素序/纸色/模板）+
**形状识别**（recognition+hold）+ 原版策略 —— 数据
模型层完备。

## Harmony 决策

文档模型全实现（含原版 `Original*` 策略）—— 模型
语义保真。

## 产出

- fixture `d02-document-model.mjs`（10 断言）。
- ADR-1256；中文报告。
