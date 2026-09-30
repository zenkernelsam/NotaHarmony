# ADR-1114：手写识别（iink + Play Asset Delivery）— fail-closed

## 状态

已接受（Phase 1170）。

## 决策

手写识别 = **MyScript iink**（专有引擎，Phase 1159）+
**Play Asset Delivery** on-demand 语言包 —— **双重
不可移植** → fail-closed：

- 识别引擎（手写→文本/数学）Harmony 无等价 —— 功能
  关闭或待第三方 Harmony 识别 SDK 重适配。
- 语言包分发 Play Asset Delivery → Harmony 资源包/
  应用内下载重适配。
- `HandwritingPackDownloadWorker`（WorkManager）→
  Harmony `BackgroundTask`/下载任务。
- 3 异常语义保留。

## 理由

`extends CoroutineWorker`、`dc5` asset-delivery 门面、
`PlayAssetDeliveryUnavailableException extends IOException`。

## 后果

手写识别功能 Harmony fail-closed（入口隐藏/置灰）；
数据侧（已有手写笔迹）仍可存取/渲染为墨迹，仅
"手写→文本/数学"识别不可用。
