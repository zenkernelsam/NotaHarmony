# Phase 1428 证据：AndroidManifest + 残余资源轴收口裁决

## Manifest 一版组件逐项

| 组件 | 原版用途 | Harmony 裁决 |
|------|----------|--------------|
| `AudioCaptureService` + `RecordingForegroundService` | 录音前台保活 | 已移植：`backgroundTaskManager` 连续任务（`OriginalRecordingSourceBackend.ets:122`） |
| `ApiGatedFirebaseInitProvider` | Firebase 惰性初始化 | fail-closed（GMS） |
| `ExportFileProvider` | 导出文件 FileProvider URI | 已覆盖：Harmony 分享/导出经系统通路，无 FileProvider 等价需求 |
| `AppUpgradeReceiver` | MY_PACKAGE_REPLACED → `zv` case1 → `tid.b` | **仅写 ART baseline profile**（profileinstaller），无应用数据工作；Harmony AOT 不等价需要 → 平台边界 |
| `HwrEngineService` | MyScript iink 绑定服务 | fail-closed（ADR-0645 转换后端门禁同界） |
| `WidgetImageProvider` + 5 widget providers | 桌面小组件 | 已裁决 ADR-0632/0634-0636/0680 |

其余 receiver/service/provider 全部 vendored：Play assetpacks、
WorkManager、Firebase ComponentDiscovery/Sessions、MLKit、GMS
measurement、Room MultiInstanceInvalidation、credentials。

## 残余资源轴

### res/xml
5 个 `app_widgets__*_widget_info`（随 widgets 裁决）、`filepaths`
（FileProvider 路径表，随 ExportFileProvider 边界）、
`core_remoteconfig__remote_config_defaults`（Firebase Remote Config
缺省表，GMS fail-closed）、`splits0`（APK split 清单，打包工件）。

### res/raw
- `feature_note_inky__inky_2026_v32.riv`：Inky AI 模式动效
  （`mp7.k`=`inky_mode_enabled` DataStore；AI 后端+Rive 运行时双重
  fail-closed）。
- `ui_designsystem__anim_grow/learn/memorize/productivity.riv` +
  `learn_confetti.riv`：启动页/Learn 特性卡 Rive 动效（各配
  `static_*` drawable 回退）；Learn 面后端门禁 → fail-closed。
- `pdfnet.res`、`pdftron_*.plugin`：PDFTron 引擎私有资源；
  Harmony PDF 通路自研 → vendored。
- `ayp_youtube_player.html`：vendored YouTube iframe player。

### res/font
`ebgaramond*`、`gtamericamono*`、`gtflairebasic*`、`inter_*`、
`proximasoft_*`、`roboto_*`、`untitledserif_*` —— 品牌/许可专有
UI 字体族，Harmony 以系统字体呈现 UI 文本；笔记正文字体选择属
`font_family` 设置轴（已裁决），非此资源面。

### res/anim|animator|interpolator|menu|layout|color|integers|dimens
全部 vendored：Material checkbox/radio 动画、fragment transitions、
`spen_recoil_*`（S Pen 回弹插值）、`qt_*`/`mini_pen_*`（S Pen 快速
工具盘）、`compat_*`/`notification_*`/`setting_qt_*`/`base_dialog_*`
等库内常量。integers.xml 另有 `google_play_services_version`、
`status_bar_notification_info_maxnum` 等平台常量。

## `feature_note__*`（194 键）残余复核

改名键已移植：content_manager→`*_page` 动作组、jump_to_*、
math_editor_*、selection_menu_*（ADR-0645 全表）、empty_note__*、
cropping_*、deselect_*、undo/redo、link_menu_*、note_deleted_*
（→`uc9` "Note unavailable" 弹窗，NotePage.ets:949-950 已对应）、
text_only banner、image_too_large_to_add、phone_title_*（标题行
点击重命名已移植，NotePage.ets:1756-1764）。

fail-closed：gif_picker_*（Klipy 服务）、youtube_*/transcripts
（远端转写服务）、version_history_*/presence_*/view_only_*/
finish_notes_*（后端协作/订阅面——view_only 经 `spb.j` 由版本
预览或共享只读触发）、hwr_panel_*（MyScript iink 方法面板，
同 ADR-0645 边界）、options_menu_inky（AI 服务）、
quick_tool_*/cd_quick_tool_*（S Pen SpenSettingQTLayout）、
download_failed/access_denied（同步态）、
options_menu_disconnect_stylus（蓝牙笔）。

## 回放

`d02-original-manifest-residual-sweep.mjs`（11 项断言）钉住连续任务
等价物、uc9 不可用弹窗、selection 全表、view_only/inky/
version_history/hwr_panel/youtube/quick_tool 无漏出、ADR-1363 文书。
