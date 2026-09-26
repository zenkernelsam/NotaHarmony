# Phase 829 — 组件属性深检

## 范围

三版 manifest 的 service/receiver/provider 块属性级解析。

## 原版发现

### Service（17 总 / 应用级 3）

- `AudioCaptureService`：fst=`mediaProjection`、exp=false；
- `RecordingForegroundService`：fst=`microphone`、exp=false；
- `HwrEngineService`：exp=false、**`process=":hwr"`**——1.4.2 新增
  （1.0.1/1.0.3 均无），配套的 `:hwr` 进程属性同版独有。

**与 Phase 828 闭环**：1.0.3 `NbApplication` 无 `getProcessName`
守卫；该守卫是 1.4.2 为 `:hwr` 进程引入的（HWR 进程加载
Application 时只跑 Crashlytics）。ProcessFreezeDetector 则
1.0.3 已存在。

### Receiver（13 总 / 应用级 6）

- `AppUpgradeReceiver`(exp=false)：MY_PACKAGE_REPLACED 自升级钩子；
- 5 个 WidgetProvider(exp=true)：APPWIDGET_UPDATE。

### Provider（5 总 / 应用级 3，均 exp=false）

- `ApiGatedFirebaseInitProvider`：initOrder=100 + directBootAware；
- `ExportFileProvider`：grantUriPermissions + @xml/filepaths；
- `WidgetImageProvider`：grantUriPermissions（卡片缩略图授权）。

Vendor 组件 14S+7R+2P 全部归因（Play/WM/Firebase/MLKit/GMS/
Room/datatransport/startup/profileinstaller）。

## Harmony 侧

microphone FGS → AUDIO_RECORDING 连续任务（820 对齐）；
mediaProjection 无等价 fail-closed；`:hwr`/MyScript 链已
fail-closed；MY_PACKAGE_REPLACED 无 bundleChange 等价登记；
两个授权 Provider → share sheet/formProvider 模式差登记。

## 验证

- 新 Replay `d02-component-attrs.mjs`：**17/17**（fst 双值、
  :hwr、版本差三分支、守卫缺位断言、receiver/provider 属性）。
- ADR-0773。
