# Phase 1170 证据 — data/handwritingrecognition（iink 语言包交付）

来源：`data/handwritingrecognition/`（4 文件）。

## 结构

- `HandwritingPackDownloadWorker extends CoroutineWorker` =
  WorkManager 工人 —— 下载手写识别语言包；
  `b(ef2)` suspend `doWork`。
- `LanguagePackUnavailableException{dc5}` = 语言包不可用
  （`dc5` = asset-delivery 门面）。
- `MathRecognitionUnsupportedException` = 数学识别不支持。
- `PlayAssetDeliveryUnavailableException extends IOException` =
  **Play Asset Delivery** 不可用。

## 判定：MyScript iink + Play Asset Delivery（双重不可移植）

手写识别 = **MyScript Interactive Ink**（Phase 1159 专有
SDK）+ **Google Play Asset Delivery** on-demand 语言包
—— 双重不可移植：

1. 识别引擎 = iink Engine/Editor（专有，Harmony 无）。
2. 语言包分发 = Play Asset Delivery（Android 商店专属）。

`HandwritingPackDownloadWorker` = 按需拉语言包（
`dc5` asset-delivery 门面 + `zb5` 注入）。

## Harmony 决策 — **fail-closed**

- 手写→文本/数学识别引擎：Harmony 无 MyScript iink —
  需自研或第三方 Harmony 识别 SDK（`hiai`/自定义）—
  **非等价**，fail-closed（识别功能关闭或降级）。
- 语言包分发：Play Asset Delivery → Harmony 资源包/
  应用内下载机制重适配。
- 3 异常语义保留（语言包不可用/数学不支持/分发不可
  用）。

## 产出

- fixture `d02-handwriting.mjs`（10 断言）。
- ADR-1114（fail-closed）；中文报告。
