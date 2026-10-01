# Phase 1438 — 叶子轴末扫收口证据

> 目标：对 `decompiled_1.4.2` 树做一次穷尽式叶子枚举，确认可移植轴无残留未判定项；
> 对本阶段最后 8 个此前未逐枚核验的叶子/族给出终局裁决并成文。

## 1. 末扫方法与范围

以 `decompiled_1.4.2` 为事实源，按资源族 + 包叶子两条线推进：

- 资源族：`res/values*/`（strings/plurals/arrays/bools/integers）、`res/xml/`、
  `res/font/`、`assets/`、`resources/`、`META-INF/`、`kotlin/`、`firebase/`、`google/`。
- 包叶子：`com.gingerlabs.{core,data,domain,feature,noteability,ui}` 全部叶子包、
  `com.samsung`、`com.myscript`、`com.google.*`、`androidx.*` vendored 树、
  entry-point（Activity/Service/Receiver/Provider/Application/WorkManager）。

凡遇叶子，先查消费者与 flag 门控，再对 Harmony 侧做 grep 验证，最后归类为
**已移植 / vendored 边界 / 后端或硬件边界 fail-closed / 调试专用 fail-closed**。

## 2. 本阶段 8 项终局裁决

### 2.1 `ui_fileimport__*`（43 键）→ 已移植

原版 1.4.2 `values/strings.xml` 中 `ui_fileimport__*` 共 43 键，覆盖：
导入分流（add_to_existing_note / create_new_note / create_single_note /
create_separate_notes）、页序排列（arrange / move_up / move_down）、
加密 PDF（enter_password / incorrect_password / unlock）、
批量与失败态（n_files / some_files_failed_to_import / file_too_large_to_import /
ntb_files_must_be_imported_separately）、无笔记/无结果（no_existing_notes_found /
no_search_results）。

Harmony 侧核验：`note/src/main/ets/ui/components/ImportDetailsSheet.ets` +
`note/src/main/resources/base/element/string.json` 中
`import_dest_separate` / `import_dest_single` / `import_dest_existing` /
`import_pdf_password_title` / `import_pdf_password_wrong` /
`import_arrange` / `import_move_up` / `partial_import` / `import_failed` 等
全套落位，导入管线 `NoteImporter.ets` 承接。**关闭。**

### 2.2 `feature_settings__*` 可移植编辑器段 → 已移植

原版设置族 203 键中订阅/账号/后端段（pro_/plan_/account/newsletter/passkey/
subscription/monthly/annual/upsell/discord/learn_limit/transcription 等）
此前已按后端边界裁决。本阶段核验剩余可移植编辑器段：
`keep_device_awake`、`auto_deselect_eraser`、`tap_anywhere`、
`palm_detection`、`shapes_detection`、`straight_lines`、`line_spacing`、
`media_object_corners`（rounded/sharp）、`text_box_paper`、`ruler_units`
（imperial/metric）、`note_view_night_mode`、`hide_status_bar`、
`hide_navigation_bar`、`default_font*`、`default_note_title`、
`include_date`/`include_time`、`text_to_speech_speed`。

Harmony 侧核验：`note/src/main/ets/data/EditorSettingsStore.ets` 含
`keepAwake`/`autoDeselectEraser`（注释明引 `o59.c` 真值表）；
`NotePage.ets` 含 `keepScreenOnApplied` + `keepAwakeGeneration` 世代守；
`SettingsPage.ets`/`PageSettingsPanel.ets` 承接其余行。**关闭。**
（`check_spelling` 行为体在 P1431 已按 `NOTE_SPELLCHECK`=DebugOnly 判 fail-closed。）

### 2.3 `ui_text__*`（90 键）→ 已移植

原版 90 键覆盖：段落样式（bold/italic/underline/strikethrough/sub/superscript）、
块型（bullet/numbered/checkbox/block_quote/code_block）、缩进与对齐、
超链接（insert/edit/clear/link_title/url）、字号、行距、
字体族与预设（font_style_*）、`lang_*` 29 门编程语言、
`kbd_shortcut_*` 20+ 键盘快捷键、text_alignment/selected/undefined_format。

Harmony 侧核验：`OriginalKeyboardChords.ets` 承接 `kbd_shortcut_*`；
`CodeSyntaxHighlighter.ets`（Prism4j 移植）+ `buildCodeLanguageMenu` 承接
`lang_*`；`TextBlockOverlay.ets`/`EditorToolbar.ets` 承接样式与对齐。**关闭。**

### 2.4 `feature_note__text_only_*` + `isTextOnly` + `grb` → 已移植（非 fail-closed）

原版 1.4.2：`h35.Y`=TEXT_ONLY_MODE（`td5` 生产远程旗标，`androidTextOnlyMode`
默认 `false`，`resources/res/xml/core_remoteconfig__remote_config_defaults.xml`；
experimentStart 2026-08-05/06）。`h45.b`/`h45.c` 生产路径经
`the.g(remoteKey)` 读 RemoteConfig 布尔，缺失/非布尔回退 `false`。

数据面：`NoteStateEntity.isTextOnly`（Room `INTEGER` 可空列 + 专属
`UPDATE ... SET isTextOnly = ? WHERE id = ?`，`xf3.java:103`）。
渲染面：`hrb` 布局策略 → `frb`=Standard / `grb`=TextOnly(contentHeight, docWidth)；
`sgn.F` 选层集：`zp2.H` 自标准集剔除 {PDF, PAGE_BREAK, BOTTOM_HIGHLIGHT,
ANIMATION, Z_INDEXABLE}，保留 {PAPER, MAIN_TEXT, SELECTION, DEBUG_OVERLAY}；
`sen.s`：TextOnly 用固定 `(docWidth, contentHeight)` 流式重排；
`c5i` 控制器 + `kbb.{f,g,h}` 内容谓词；`q4i` 七种退出原因
（ImportedFile/InsertedImage/ManualExit/SwitchedTools/OpenedContentManager/
LegacyDaemon/InsertedSticky）；横幅/通知文案六键。

Harmony 侧核验：`NoteRepositoryImpl.ets` 已含 `isTextOnly` 列读写 +
`saveIsTextOnly`（专属 UPDATE，`xf3` 对应物，`NoteRepositoryImpl.ets:991`）；
`NotePage.ets` 含 `textOnlySignal`/`textOnlyExitSignal`/`textOnlyActive`
与 `pdl.java:214` 对应菜单项；`NoteCanvasView.ets:274` 含 `grb.TextOnly`
流式排版参数（页边距与块间间隔）。**关闭（已移植路径，不走旗标裁决）。**

### 2.5 `res/values/arrays.xml` 残留 → 三星 S-Pen SDK vendored

`arrays.xml` 中除 `feature_learn__chat_card_headers`（learn 族已裁决）外，
全部为 `spen_setting_swatch_1..23`（各 8 色）、`spen_adaptive_light_color`（65 色）、
`spen_adaptive_dark_color`（65 色）、`spen_adaptive_standard_color`（39 色）。
消费者定位于 `sources/com/samsung/android/sdk/pen/setting/color/`：
`SpenColorPaletteUtil` / `SpenSettingUtilColor` / `SpenReverseColorTheme` —
三星手写笔 SDK 自带调色板，属 vendored 资源（与 `com.samsung` 树、
`libSPenBase` 等同一边界，P1433 已就 `config.arm64_v8a` 三星原生库裁决）。
**关闭（vendored 边界）。**

### 2.6 `data/` 后端 worker 族 → 已逐条裁决

`NoteOpsUpdaterWorker` / `LibraryStateUploaderWorker` /
`HandwritingPackDownloadWorker` / `TemplatePageSyncWorker` /
`CustomTemplateSyncWorker` / `GalleryMutationUploaderWorker` —
同步/上传/下载均依赖 Play Services/自有后端，此前各 Phase ADR 已覆盖
（ADR-0652 转写、ADR-0786/0662 订阅与配额、P1433 split 轴、P1435 维护编排
`cs0` SYNC-tag）。本阶段复核无新增可移植件。**关闭（fail-closed 维持）。**

### 2.7 `app/resume` + Receiver + Provider 族 → 平台/后端边界已裁决

`AppUpgradeReceiver`（BOOT/MY_PACKAGE_REPLACED 重启恢复）、
`MissingNativeLibraryActivity`（ABI 缺库兜底）、`FileProvider`
（`androidx.core.content` vendored）、`DemoResetWorker`（零售演示，
ADR-0719/0767）、`ui/support` Zendesk、`noteability` deep-link Activity —
全部已在对应 Phase 裁决或移植（深度链接见 `module.json5` actions）。**关闭。**

### 2.8 XAPK split 轴 → P1433 已裁决

`config.<locale>`×15（仅 `resources.arsc` 翻译）、`config.xxhdpi`
（vendored drawable + widget 标签 + onboarding webp）、
`config.arm64_v8a`（MyScript iink/PDFNet/MLKit/crashlytics/rive/icing/
datastore/libSPenBase 等 vendored natives）、`stickers.apk`
（安装时 asset pack ~2900 webp + CDN prefetch，`h35.z0`=`rd5`
InternalUserOnly 门控）。**关闭。**

## 3. 结论

经穷尽枚举，`decompiled_1.4.2` 树内不再存在"未判定且可移植"的叶子轴；
剩余项全部归入 vendored 边界、后端/硬件边界、调试专用或已移植四类之一。
T-042（原版 APK 版本追踪）按硬约束保留为整个 Goal 最后一项，不在本阶段触碰。
