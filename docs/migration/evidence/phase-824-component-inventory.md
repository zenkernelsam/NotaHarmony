# Phase 824 — Manifest 应用组件清单闭合（receiver/service/provider）

证据来源：三版 `AndroidManifest.xml` 逐项提取；Harmony `module.json5` +
`noteformability/` 卡片能力 + `OriginalRecordingSourceBackend.ets`。

## 一、Receiver（6 应用级，三版本零差异）

| Receiver | intent action | Harmony 等价 |
|---|---|---|
| AppUpgradeReceiver | `MY_PACKAGE_REPLACED` | 升级重初始化——Harmony 端由 DB_VERSION 阶梯迁移器 + 启动链承担（应用升级后首次启动即迁移） |
| CreateNoteWidgetProvider | APPWIDGET_UPDATE + LOCALE_CHANGED | `noteformability` 卡片族（804 已映射） |
| CreateRecordingWidgetProvider | 同上 | 同上 |
| RecentNotesWidgetProvider | 同上 | `RecentNotesFormFeed` |
| NoteThumbnailWidgetProvider | 同上 | `NoteThumbnailFormFeed` |
| FolderNotesWidgetProvider | 同上 | `FolderNotesFormFeed` |

vendor receiver（GCM/startup/profileinstaller 等 7 个）fail-closed。

## 二、Service（应用级 2→2→3）

| Service | 版本 | 语义 | Harmony 等价 |
|---|---|---|---|
| RecordingForegroundService | 全版本 | 录音前台服务 | AUDIO_RECORDING 连续任务（820） |
| AudioCaptureService | 全版本 | 内录音频捕获 | 同一连续任务管线 |
| **HwrEngineService** | **1.4.2 新增** | MyScript 手写识别引擎服务 | Harmony 手写识别经 `OriginalHandwritingRecognitionContextAdapter` 走引擎适配层 |

vendor service（playcore/firebase/iap 等）fail-closed。

## 三、Provider（应用级 1→2→3）

| Provider | 版本 | 语义 | Harmony 等价 |
|---|---|---|---|
| WidgetImageProvider | 全版本 | 卡片缩略图 Uri 供给 | 卡片图经 formBinding/像素图直接注入 |
| **ExportFileProvider** | **1.0.3 新增**（817） | 导出文件共享（替换旧 FileProvider） | Harmony fd-share/FileUri 共享机制 |
| **ApiGatedFirebaseInitProvider** | **1.4.2 新增**（818） | API 门禁的 Firebase 延迟初始化 | 无对应（Firebase fail-closed） |

## 四、结论

manifest 应用组件全量闭合：receiver 6 个三版零差；service 2→3
（HwrEngineService 手写引擎服务上车）；provider 1→2→3
（ExportFileProvider 替换 + ApiGatedFirebaseInitProvider 门禁初始化）。
与 Phase 800（组件计数层）形成明细级闭环，每个应用级组件均有
Harmony 等价映射或已登记边界。
