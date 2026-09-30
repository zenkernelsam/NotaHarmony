# ADR-1169：ML Kit Vision 依赖（OCR+文档扫描）

## 状态

已接受（Phase 1225）。

## 决策

- `TextRecognizer`（bundled Latin OCR，`hhj`/`ztg`/`qyg`）
  → Harmony `@kit.VisionKit` `textRecognition`。
- `DocumentScanner`（`re`/`p4h` + `GmsDocumentScanningDelegateActivity`
  GMS 委托）→ **fail-closed**（无 GMS 委托通道；
  Harmony 侧以相机+OCR 自研或 `DocGallery` 替代）。

## 理由

60 文件 mlkit 引用；`vision.text` bundled latin 模型
（离线）+ `vision.documentscanner`（GMS 委托
Activity，`registerForActivityResult`+`f35` 契约）；
`MlKitInitProvider` 自启组件。

## 后果

OCR 可由 VisionKit 等价；文档扫描的 GMS 委托管线
不可直迁 —— Harmony 需重实现相机扫描或显式
fail-closed。
