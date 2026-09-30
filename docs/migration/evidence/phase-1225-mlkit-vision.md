# Phase 1225 证据 — Google ML Kit Vision 依赖（OCR + 文档扫描）

来源：`com/google/mlkit/**`（8+60 引用）+ `defpackage/{hhj,ztg,qyg,re,p4h,spd}.java`。

## 两个 ML Kit Vision 功能

| 功能 | SDK | 应用侧类 | 用途 |
|---|---|---|---|
| **文本识别 OCR** | `mlkit.vision.text`（`text_bundled_common` bundled + `dynamite/text/latin` Latin 模型） | `hhj`/`ztg`/`qyg` → `TextRecognizer` | 图中文本/手写识别（搜索/选字） |
| **文档扫描** | `mlkit.vision.documentscanner` | `re`/`p4h` → `DocumentScanner` + `GmsDocumentScanningDelegateActivity` | 扫纸质文档入笔记 |

## SDK 内部结构

- `common/MlKitComponentDiscoveryService`/`MlKitInitProvider`
  = 组件自启。
- `common/MlKitException` = 错误面。
- `internal/mlkit_vision_text_bundled_common/*` =
  **bundled 离线模型**（`a`/`b`/`zbti`/`zbup`/`zbuq`/
  `zbwk`/`zbwu` — 原生管线）。
- `libraries/vision/visionkit/pipeline/alt/NativePipelineImpl`
  = native pipeline。
- `dynamite/text/{common,latin}` = dynamite 模块描述
  （GMS 动态加载 / bundled 双模式）。
- `spd` 合并 handler（`OnSuccess/OnFailure/RemoteCall`
  + `GmsDocScanDelAct` 回调）。

## 判定

ML Kit Vision = **GMS 双重依赖**：
- 离线 OCR（bundled latin 模型 —— 图中文本识别；
  与手写识别 `MyScript iink` Phase 1159 互补）。
- 文档扫描（GMS 委托 Activity —— 相机扫描边界）。

## Harmony 决策（fail-closed）

- ML Kit OCR → Harmony `@kit.VisionKit`
  `textRecognition`（原生 OCR 等价）。
- DocumentScanner → Harmony `DocGallery`/`scanKit` 或
  相机+OCR 自研 —— 无 GMS 委托 → **fail-closed ADR**。

## 产出

- fixture `d02-mlkit-vision.mjs`（10 断言）。
- ADR-1169；中文报告。
