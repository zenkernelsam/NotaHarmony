# Phase 1281 证据 — PDFTron PDFNet PDF 引擎（原生 JNI）

来源：`com/pdftron/*`（27 JNI stub 文件 → 原生
`libPDFNetC.so`）。

## API 面

```
PDFNet        // SDK 入口（initialize+license）
PDFDoc        // 文档（页增删/字段/保存/加密）
Page          // 单页（旋转/裁剪/批注）
PDFViewCtrl   // 渲染视图
PDFDraw       // 光栅化
Convert       // Office/图片→PDF 转换
Annot         // 批注（native GetRect/GetType/IsValid）
annots/Link   // 链接批注
Highlights    // 高亮/下划线/删除线批注
Stamper       // 盖章/水印
TextExtractor // 文本提取（字/行/矩形）
TextSearchResult // 搜索
sdf/Obj ObjSet DictIterator  // SDF 底层对象模型
filters/CustomFilter/Filter  // IO 过滤
```

## `Annot` = JNI 批注

`static native long GetRect(long)`/`GetType`/`IsValid` —
— 全 native：Java 层只是 long-handle 封装，真实现在
`libPDFNetC.so`。

## 语义

**PDFTron PDFNet 商业 SDK** —— PDF 导入/渲染/批注
（ink/highlight/text/stamp/link）/文本提取/导出 —
— Notability PDF 标注+导出核心，全原生。

## Harmony 决策

PDFTron → Harmony 无移植 —— PDF fail-closed：
- 渲染/批注 → 系统 PDF 组件或自研 GL 渲染；
- 文本提取 → `pdf` 解析库（无原生）；
- 导出 → 手写 PDF writer（`PagePdfExporter` 已有）；
- 商业许可+原生库不移植 —— fail-closed。

## 产出

- fixture `d02-pdftron.mjs`（10 断言）。
- ADR-1225（fail-closed）；中文报告。
