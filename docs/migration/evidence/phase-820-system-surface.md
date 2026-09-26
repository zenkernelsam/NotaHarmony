# Phase 820 — 系统表面闭合：通知渠道 + 启动器图标分层

证据来源：`decompiled_1.0.3/1.4.2`（manifest、`res/mipmap-anydpi`、`res/drawable/ic_launcher_*`、`res/values/colors.xml`、
`RecordingForegroundService`/`AudioCaptureService`）；Harmony `AppScope/resources/base/media/`、
`OriginalRecordingSourceBackend.ets`、`module.json5`。

## 一、通知渠道清单（1.0.3 = 1.4.2，零版本差）

| 渠道 ID | 归属 | 重要性 | 消费者 |
|---|---|---|---|
| `notability_recording` | 应用 | IMPORTANCE_LOW(2) | `RecordingForegroundService`（名称键 `feature_note_toolbox__recording_notification_channel_name`） |
| `AudioCapture channel` | 应用 | IMPORTANCE_DEFAULT(3) | `AudioCaptureService`（"Notability Audio Capture Service Channel"） |
| `com.google.android.gms.availability` | GMS | — | 厂商 |
| `playcore-assetpacks-service-notification-channel` | Play 核心库 | — | 厂商 |

应用级仅 2 个渠道，均为前台服务合规通知——Android 要求前台服务挂在渠道上。

### Harmony 等价

Harmony 无应用级通知渠道 API；录音长时任务由
`backgroundTaskManager.startBackgroundRunning(context, BackgroundMode.AUDIO_RECORDING, agent)`
启动（`OriginalRecordingSourceBackend.ets:137-138`），系统管理常驻通知卡片。
原版两个渠道的存在理由是平台合规（渠道壳），非用户功能——机制等价成立，
渠道粒度本身 fail-closed。vendor 渠道（GMS/playcore）fail-closed。

## 二、启动器图标分层对照

### 原版（adaptive icon，三层）

`res/mipmap-anydpi/ic_launcher.xml`：

| 层 | 资源 | 内容 |
|---|---|---|
| background | `ic_launcher_background.xml` | 平铺向量，纯色 `#5497fe`（蓝） |
| foreground | `ic_launcher_foreground.xml` | app-mark 向量：橙体 `#ff8e4d` + 米尖 `#f5ebd9` + 黑色元素（铅笔形） |
| monochrome | `ic_launcher_monochrome.xml` | themed-icon 单色层，`pathData="@string/ui_designsystem__app_mark_path"`（Phase 812 登记的共享 app-mark） |

### Harmony（layered_image，两层）

`AppScope/resources/base/media/layered_image.json` + PNG：

| 层 | 文件 | 实测像素 |
|---|---|---|
| background.png | 91,942 B | 全不透明蓝色渐变（角 #2C79F4 → 深 #1664F6 族） |
| foreground.png | 15,325 B | 394,260 不透明像素，全白（透明底上白色方圆角栅格标记） |

### 差异判定

1. **色相族一致**（蓝底）但原版为平铺纯色，Harmony 用渐变 PNG —— 平台风格化差异。
2. **前景标记不同**：原版铅笔 app-mark（三色向量）vs Harmony 白色方圆角栅格——
   属 NotaHarmony 品牌标记（与 Phase 794/819 的自命名身份分叉一致，登记非缺陷）。
3. **monochrome 层无对应物**：Harmony layered-image 仅 bg+fg 两层，
   无 themed-icon 通道 —— fail-closed 平台缺失。

## 三、附注：widget LOCALE_CHANGED

`CreateNoteWidgetProvider`/`CreateRecordingWidgetProvider` 声明
`APPWIDGET_UPDATE` + `LOCALE_CHANGED`——原版卡片随系统语言切换刷新标签。
Harmony FormExtensionAbility 的卡片重渲染由系统语言切换事件驱动，平台等价。

## 四、结论

通知渠道与图标分层两个系统表面完成闭合：原版 4 渠道全部归类映射
（2 应用级由 AUDIO_RECORDING 长时任务机制等价，2 厂商 fail-closed）；
图标层差异登记为品牌标记分叉 + monochrome 层平台缺失。
