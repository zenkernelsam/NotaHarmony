# Phase 1292 报告 — 手写识别包下载

## 完成内容

- `HandwritingPackDownloadWorker`（CoroutineWorker+
  `zb5` Play AssetDelivery 安装器）—— 按需下载
  MyScript 手写语言包；`LanguagePackUnavailable`/
  `MathRecognitionUnsupported`/`PlayAssetDelivery
  Unavailable` —— 手写识别 = iink 引擎+Play 资产包。

## 产出

- evidence `phase-1292-handwriting.md`
- fixture `d02-handwriting.mjs`（10/10）
- ADR-1236（fail-closed）
