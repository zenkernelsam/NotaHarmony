# Phase 863 证据 — 手写识别语言包投递层登记

## 目的

`data/handwritingrecognition` 包此前未挖掘。本阶段登记原版的
**双通道语言包投递契约**（内置集 + Play Asset Delivery/CDN 下载）
与三道异常门，核对 Harmony 的 fail-closed 适配。

## 原版证据（`decompiled_1.0.3`）

### `dc5` — 23 语言枚举（`defpackage/dc5.java`）

```
de_DE/de, en_US/en, es_ES/es, fr_FR/fr, it_IT/it, ja_JP/ja, ko_KR/ko,
nl_NL/nl, no_NO/nb, pt_BR/pt, ru_RU/ru, tr_TR/tr, zh_CN/zh-Hans,
zh_TW/zh-Hant, th_TH/th, fil_PH/fil, id_ID/id, ms_MY/ms, pl_PL/pl,
sv_SE/sv, uk_UA/uk, vi_VN/vi, da_DK/da   — 共 23
```

- `dc5.L` = `O`（**en_US** 默认）
- `dc5.N` = `{"TW","HK","MO"}` — zh-Hant 地区集
- `dc5.K` = `sh8`（查找助手）；`dc5.M` = 排序列表
- `I`=localeCode（写 MyScript `lang/recognizer.lang`）、`J`=languageTag

### `gg1` — `zb5` 语言包安装器（`defpackage/gg1.java`）

- `h = ys2.P(dc5.O)` — **内置集仅 {en_US}**；其余 22 语言全部需下载
- `i = "4.4.0"` — 包资产 schema 版本
- `j = "https://android-assets.notability.com"` — **CDN 回退主机**
  （投递为双通道：Play Asset Delivery 包 + 自有 CDN）
- `b(dc5)`：已内置或已装路径非空 → 可用
- `c(dc5)`：未装 → `eoh.b(dag, dc5)` 经 WorkManager 入队
  `HandwritingPackDownloadWorker`
- `d(dc5)`：路径解析失败 → `LanguagePackUnavailableException`
  （"No recognition assets available for \<lang\>"）

### 异常门（`data/handwritingrecognition/`）

- `LanguagePackUnavailableException` — 语言包缺失（fail-closed）
- `MathRecognitionUnsupportedException` —
  **"MyScript certificate does not support the Math recognizer"**
  （证书许可证门控数学识别器）
- `PlayAssetDeliveryUnavailableException`(IOException) —
  Play 交付不可用（`HandwritingPackDownloadWorker` 经 `zb5` 安装器
  调用 Play SplitInstall/AssetPack API — GMS 专属）

## Harmony 侧（`note/src/main/ets`）

- `OriginalHandwritingLanguagePolicy.ets`：**23 行语言表与 dc5 逐一相同**
  （localeCode/languageTag/displayName 对应）；默认 en_US；zh 经
  script/country（TW/HK/MO `isTraditionalChineseCountry` ↔ dc5.N）；
  遗留 ISO 映射 tl→fil、in→id、no|nn→nb。
- 解析链 `NOTE_REGISTER → GLOBAL_PREFERENCE → SYSTEM_LOCALE →
  DEFAULT_ENGLISH`（jc5.e + sh8.D 语义：不合法值不猜测、继续下一源）。
- `OriginalHandwritingRecognition.ets`：provider 为 null/不可用 →
  返回 null（fail-closed）；`dc5.I` localeCode 传入识别器（非 tag）。
- `OriginalHandwritingProviderCapabilityPolicy.ets`：syscap/
  笔画原生/逐调用语言锁/语言覆盖四道兼容性闸门 —
  HarmonyOS 无 Play Asset Delivery 与 MyScript 证书体系，
  语言包投递整体 fail-closed；内置 en_US 语义由
  「系统能力不可用 → 不兼容」门表达。

## 结论

HWR 投递层登记完毕：dc5 23 语言 + en_US 内置唯一 + CDN/Play 双通道
+ 三异常门；Harmony 侧语言表/解析链逐一对齐，投递机制 fail-closed
（MyScript 证书与 Play Asset Delivery 皆不可移植）。无源改动。
