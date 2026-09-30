# ADR-1236：手写识别包下载

## 状态

已接受（Phase 1292）—— **fail-closed**。

## 决策

MyScript iink+Play Asset Delivery → Harmony 无对应，
fail-closed；语言包需自有 CDN 下载。

## 理由

`HandwritingPackDownloadWorker`（`zb5` AssetPackManager
安装器按需下载语言包）+LanguagePackUnavailable/
MathRecognitionUnsupported/PlayAssetDeliveryUnavailable
—— 手写识别 = MyScript 引擎+Play 按需资产包；
Harmony 无 Play Asset Delivery。

## 后果

Harmony 手写识别 = 引擎+资产包双 fail-closed —
— 语言包需自有分发，识别特性降级。
