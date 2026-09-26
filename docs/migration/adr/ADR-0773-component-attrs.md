# ADR-0773 — 组件属性级映射（service/receiver/provider）

- 状态：已接受
- 证据：`docs/migration/evidence/phase-829-component-attrs.md`
- 回放：`docs/migration/replays/d02-component-attrs.mjs`（17/17）

## 原版面（1.4.2 manifest）

- Service 17：应用级 3（AudioCapture=fst:mediaProjection、
  Recording=fst:microphone、HwrEngine=**:hwr 进程**），vendor 14。
- Receiver 13：应用级 6（AppUpgrade=MY_PACKAGE_REPLACED +
  5 widget providers），vendor 7。
- Provider 5：应用级 3（ApiGatedFirebaseInit 带 initOrder=100/
  directBootAware、ExportFile 带 filepaths+授权、WidgetImage
  带授权），vendor 2。

## 版本差

`HwrEngineService` + `:hwr` 进程为 **1.4.2 独有**——与
NbApplication 新增的 `getProcessName` 守卫互为因果（HWR 进程
也会加载 Application，守卫使其只跑 Crashlytics）。

## 决定

1. `foregroundServiceType=microphone` → Harmony `AUDIO_RECORDING`
   continuous task（Phase 820 已对齐）。
2. `mediaProjection` 音频内录路径 fail-closed（Harmony 无等价
   系统级内录 API 于本形态）。
3. `:hwr` 进程隔离不可移植——MyScript HWR 引擎整体 fail-closed，
   进程隔离需求随之消失。
4. `AppUpgradeReceiver`(MY_PACKAGE_REPLACED) 登记：Harmony ETS
   无 bundleChange 订阅等价物，升级缓存失效由版本号比对承担。
5. `ExportFileProvider`/`WidgetImageProvider` content:// 授权模型
   → Harmony 系统 share sheet / formProvider 数据通道，模式差登记。

## 后果

- 组件级属性面闭合；vendor 组件全部归因。
- Replay 固化 fst、:hwr、版本差、initOrder/directBootAware、
  授权属性 17 项断言。
