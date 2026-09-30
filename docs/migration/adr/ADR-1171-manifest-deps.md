# ADR-1171：Manifest 依赖普查（GMS/Firebase/Play 全栈）

## 状态

已接受（Phase 1227）。

## 决策

97 组件全栈 = Firebase×7 遥测 + Google 登录 + GA4 +
Play Billing + Play Asset Delivery + ML Kit + CCT —
Harmony **全部 fail-closed** 或换 HMS 对应
（`@kit.AccountKit` 登录/`HMS Analytics`/`HMS IAP`/
`HMS PushKit`/`@kit.VisionKit`）。

## 理由

manifest 实名：`crashlytics/perf/remoteconfig/
sessions/installations/measurement/datatransport/
auth.signin/billingclient/assetpacks/mlkit/
GmsDocumentScanningDelegateActivity` —— GMS-family
完整覆盖。

## 后果

全部 GMS 边界已枚举完毕——Harmony 迁移边界：
登录/IAP/资源包/扫描/OCR/遥测 各自 fail-closed 或
HMS 等价；无静默替代。
