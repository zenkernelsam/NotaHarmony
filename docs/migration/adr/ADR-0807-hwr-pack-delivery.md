# ADR-0807 — 手写识别语言包投递层登记（dc5/gg1/异常门）

## 状态

accepted（文档+fixture，无源改动）

## 原版证据（`decompiled_1.0.3`）

- `dc5`：23 语言枚举（localeCode→languageTag），`L`=en_US 默认、
  `N`={TW,HK,MO} zh-Hant 地区集、`K`=sh8 查找、`M` 排序列表。
- `gg1`（`zb5` 安装器）：内置集仅 {en_US}；其余 22 语言经
  Play Asset Delivery 包或自有 CDN `android-assets.notability.com`
  （schema v4.4.0）下载；未装即 `LanguagePackUnavailableException`。
- `HandwritingPackDownloadWorker`：WorkManager 后台下载。
- `MathRecognitionUnsupportedException`：MyScript 证书门控数学识别器；
  `PlayAssetDeliveryUnavailableException`(IOException)。

## Harmony 决策

- 语言表/默认/地区集/解析链与原版逐一对齐
  （`OriginalHandwritingLanguagePolicy`）。
- 投递机制 fail-closed：HarmonyOS 无 Play Asset Delivery 与
  MyScript 证书体系；识别经 `OriginalHandwritingRecognition`
  的 provider 边界（null→null）+ `ProviderCapabilityPolicy`
  四道兼容门表达。

## Parity 状态

- 等价：语言/解析/默认语义全对齐。
- fail-closed：语言包下载通道不移植（GMS/专有 CDN），
  数学识别器的证书门亦随投递层一并 fail-closed。

## 验证

- `d02-hwr-pack-delivery.mjs`：33/33 通过。
- 全量 Replay 与双 HAP 构建见 Phase 863 报告/提交。
