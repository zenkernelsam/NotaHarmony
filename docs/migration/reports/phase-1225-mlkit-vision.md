# Phase 1225 报告 — ML Kit Vision 依赖

## 完成内容

- `TextRecognizer`（bundled Latin OCR）→ `hhj`/`ztg`/`qyg`；
- `DocumentScanner` + `GmsDocumentScanningDelegateActivity`（GMS 委托）→ `re`/`p4h`；
- 60 文件引用、`MlKitInitProvider`/`DiscoveryService` 自启、`NativePipelineImpl` native 管线。

## 产出

- evidence `phase-1225-mlkit-vision.md`
- fixture `d02-mlkit-vision.mjs`（10/10）
- ADR-1169
