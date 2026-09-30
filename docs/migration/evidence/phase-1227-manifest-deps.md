# Phase 1227 证据 — Manifest 依赖普查（GMS/Firebase/Play 面）

来源：`decompiled_1.0.3/resources/AndroidManifest.xml`（97 组件）。

## Firebase 套件（12 注册器）

| 模块 | Manifest 条目 |
|---|---|
| Crashlytics | `CrashlyticsRegistrar`/`FirebaseCrashlyticsKtxRegistrar` |
| Perf 监控 | `FirebasePerfRegistrar`/`FirebasePerfKtxRegistrar` |
| RemoteConfig | `RemoteConfigRegistrar`/`FirebaseRemoteConfigKtxRegistrar` |
| Installations | `FirebaseInstallationsRegistrar`/`Ktx` |
| Sessions | `FirebaseSessionsRegistrar` + `SessionLifecycleService` |
| Analytics/ABT | `AnalyticsConnectorRegistrar`/`AbtRegistrar`/`AppMeasurement{Service,Receiver,Job}` |
| 数据链路 | `datatransport TransportRegistrar` + `CctBackendFactory`/`TransportBackendDiscovery`/`JobInfoScheduler`/`AlarmManagerScheduler` |
| 自启 | `FirebaseInitProvider`/`ComponentDiscoveryService` |

## GMS

- `auth.api.signin` = **Google 登录**（RevocationBoundService/SignInHubActivity/REVOCATION）。
- `measurement` = AppMeasurement（GA4 埋点）。
- `common.api.GoogleApiActivity` = GMS 委托 UI。

## Play 核心

- `billingclient` + `BillingOverrideService` = Play Billing（Phase 1169 对齐）。
- `play.core.assetpacks` = **Play Asset Delivery**（`AssetPackExtraction`/`ExtractionForegroundService`/`SessionStateBroadcastReceiver`/`ACTION`）—— 手写包/资源按需下载（Phase 1170 对齐）。
- `common.PlayCoreDialogWrapperActivity` + `finsky.BIND`。

## ML Kit（Phase 1225/1226 对齐）

- `CommonComponentRegistrar`/`MlKitComponentDiscoveryService`/`MlKitInitProvider`/`VisionCommonRegistrar`/`TextRegistrar`/`GmsDocumentScanningDelegateActivity`。

## 判定

Manifest 暴露 **GMS/Firebase/Play 全栈**（97 组件）：
Firebase 遥测×7 + Google 登录 + GA4 + Play Billing +
Play Asset Delivery + ML Kit + CCT 数据链路 ——
Harmony 全部 **fail-closed** 或换对应 HMS Kit。

## 产出

- fixture `d02-manifest-deps.mjs`（10 断言）。
- ADR-1171；中文报告。
