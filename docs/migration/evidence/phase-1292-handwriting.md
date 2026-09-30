# Phase 1292 证据 — data/handwritingrecognition 手写包下载

来源：`data/handwritingrecognition/*` + `com/myscript/iink`
（Phase 1280）。

## 组件

```
HandwritingPackDownloadWorker extends CoroutineWorker
    {zb5 installer}                // 按需下载手写语言包
LanguagePackUnavailableException   // 语言包不可用
MathRecognitionUnsupportedException// 数学识别不支持
PlayAssetDeliveryUnavailableException // Play Asset Delivery 不可用
```

`zb5` = Play Asset Delivery 安装器（`AssetPackManager`/
`AssetPackState` —— on-demand 资产包）。

## 语义

**手写识别 = MyScript iink + Play Asset Delivery**：
- 识别引擎 `Engine`/`Editor`（Phase 1280）；
- 语言包 = Play **Asset Pack**（按需下载的识别资源 —
  en/zh/math 等 pack）；
- `HandwritingPackDownloadWorker` 后台下载+安装 pack；
- 数学识别单独 gated（MathRecognitionUnsupported）；
- Harmony/无 Play 时 AssetDelivery 不可用 → 语言包
  无法按需下发。

## Harmony 决策

MyScript iink fail-closed（Phase 1280）；Play Asset
Delivery → Harmony 无对应（无按需资产包）→ 语言包
需 bundle 或自有 CDN 下载 —— 双层 fail-closed。

## 产出

- fixture `d02-handwriting.mjs`（10 断言）。
- ADR-1236（fail-closed）；中文报告。
