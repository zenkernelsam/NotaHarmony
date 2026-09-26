# Phase 829 — 组件属性深检（service/receiver/provider）

证据：`decompiled_*/resources/AndroidManifest.xml`（1.0.1/1.0.3/1.4.2 三版）

## 一、应用级 Service（3 个，1.4.2）

| Service | foregroundServiceType | exported | process |
|---------|----------------------|----------|---------|
| `AudioCaptureService` | `mediaProjection` | false | 主进程 |
| `RecordingForegroundService` | `microphone` | false | 主进程 |
| `HwrEngineService` | （无） | false | **`:hwr`** |

**版本差**：`HwrEngineService` 为 **1.4.2 新增**（1.0.1/1.0.3 均无）；
`:hwr` 进程属性同理仅存于 1.4.2（manifest line 262）。

**关联 Phase 828**：1.0.3 `NbApplication` **无** `getProcessName`
守卫；该守卫为 1.4.2 新增——正是为 `:hwr` 进程隔离而引入
（HWR 引擎在独立进程内也走 Application.onCreate，守卫使其
只初始化 Crashlytics）。ProcessFreezeDetector 在 1.0.3 已存在
（非新增）。

## 二、应用级 Receiver（6 个）

| Receiver | exported | 动作 |
|----------|----------|------|
| `AppUpgradeReceiver` | false | `MY_PACKAGE_REPLACED`（自升级钩子） |
| `CreateNoteWidgetProvider` | true | APPWIDGET_UPDATE |
| `CreateRecordingWidgetProvider` | true | APPWIDGET_UPDATE |
| `RecentNotesWidgetProvider` | true | APPWIDGET_UPDATE |
| `NoteThumbnailWidgetProvider` | true | APPWIDGET_UPDATE |
| `FolderNotesWidgetProvider` | true | APPWIDGET_UPDATE |

## 三、应用级 Provider（3 个，均 exp=false）

- `ApiGatedFirebaseInitProvider`（Firebase 门控初始化）：
  `initOrder="100"` + `directBootAware="true"`（先于
  androidx.startup 的自定义顺序引导）。
- `ExportFileProvider`（导出分享 content:// 授权）：
  `grantUriPermissions="true"` + `FILE_PROVIDER_PATHS →
  @xml/filepaths`。
- `WidgetImageProvider`（小组件缩略图 content:// 授权）：
  `grantUriPermissions="true"`。

## 四、Vendor 组件（已识别，不计入应用面）

Service 14 个：Play assetpacks×2、WorkManager×2、Firebase/
MLKit/CredentialManager discovery×3、GMS measurement×2、
Room invalidation、Firebase sessions、GMS signin revocation、
datatransport×2。
Receiver 7 个：Play session、WM force-stop/reschedule/diagnostics、
GMS measurement、profileinstaller、datatransport alarm。
Provider 2 个：androidx.startup、MlKitInitProvider。

## 五、Harmony 侧映射

| 原版组件 | Harmony 等价 | 状态 |
|---------|-------------|------|
| RecordingForegroundService(microphone) | `AUDIO_RECORDING` continuous task（820 已登记） | 对齐 |
| AudioCaptureService(mediaProjection) | 系统录屏/媒体投影无对应 picker | fail-closed（音频回放内录不支持） |
| HwrEngineService(:hwr) | MyScript lite fail-closed（手写识别引擎整链不可移植） | 已登记 |
| AppUpgradeReceiver | 无 bundle 升级回调监听（ETS 内无 bundleChange 订阅） | 登记 |
| 5 widget providers | Harmony FormExtensionAbility 卡片（Phase 804 已映射） | 对齐 |
| ExportFileProvider | share 走系统 share sheet + 沙箱 URI | 对齐（模式差登记） |
| WidgetImageProvider | 卡片图片走 formProvider updateForm 数据 | 对齐（模式差登记） |

## 六、结论

- 组件清单：service 8→17（vendor 占多数）、receiver 12→13、
  provider 3→5；应用级 3+6+3。
- 唯一应用级版本差：**HwrEngineService + `:hwr` 进程**（1.4.2），
  与 Phase 828 的进程分层守卫互为因果证据。
- `foregroundServiceType` 声明精确到 mediaProjection/microphone；
  Harmony 侧仅 microphone 类有等价连续任务模式。
