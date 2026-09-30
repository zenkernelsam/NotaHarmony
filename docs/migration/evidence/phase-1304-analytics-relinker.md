# Phase 1304 证据 — 分析 SDK + ReLinker + Wire

来源：`com/{getkeepsafe,singular,mixpanel,squareup}/`
+ `sso/`。

## `getkeepsafe/relinker` = ReLinker（原生库加载器）

`MissingLibraryException` —— 原生 .so 加载失败重试+
fallback；抛 `MissingLibraryException` → `Missing
NativeLibraryActivity` 弹窗（Phase 1296 闭环！）。

## `com/singular/sdk` = Singular（归因/MMP）

`Attributes`/`DeferredDeepLink`/`Events`/`Api` —— 营销
归因+延迟深链+事件追踪 —— **MMP 归因**分析。

## `com/mixpanel` = Mixpanel 分析（内部封装）。

## `com/squareup/wire` = **Square Wire** protobuf —
— 又一层 wire 序列化（与 protobuf-lite 并存）。

## `sso/` = `GoogleCredentialException` —— SSO 凭据
错误（Google SSO 集成）。

## 分析 SDK 全景

Firebase Analytics（AppMeasurement）+ **Mixpanel** +
**Singular**（归因）+ Google Analytics —— **多提供
商分析栈**（产品分析+营销归因+崩溃/性能）。

## Harmony 决策

- ReLinker → Harmony 无对应（原生 ABI 管理不同）→
  Harmony 直接 `hilog`+fail-closed（加载失败提示）。
- Singular/Mixpanel → Harmony 分析等价物或移除（归因/
  产品分析 → `@kit.AdsKit`/`hms` analytics 或移除）。
- Wire protobuf → ArkTS protobuf 序列化。

## 产出

- fixture `d02-analytics-relinker.mjs`（10 断言）。
- ADR-1248；中文报告。
