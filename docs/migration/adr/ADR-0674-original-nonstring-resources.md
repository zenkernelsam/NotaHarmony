# ADR-0674 非字符串资源尾部：app_widgets 视觉对齐 + arrays/bools/integers/dimens/styles 边界登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：726
- 证据：`docs/migration/evidence/original-nonstring-resources-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-widget-visuals.mjs`

## 背景

`plurals.xml` 收口（ADR-0673）后，审计向量推进到其余非 string 资源族。
除 `app_widgets__*` 调色板/圆角外，剩余键全部落在平台或 SDK 内部：

- `arrays.xml` 79 键：`spen_adaptive_*`/`spen_setting_swatch_*`/
  `spen_setting_swatch_name_*`（Samsung SPen SDK 调色板内部数据，
  ADR-0672 已登记 SPen 资源边界）+ `feature_learn__chat_card_headers`
  （Learn AI 建议卡标题——账号/AI 后端边界，ADR-0652）。
- `bools.xml` 5 键：Firebase/WorkManager/前台服务默认开关——平台与
  GMS 库内部，无对应面。
- `integers.xml`：`qt_*`/`setting_qt_*`（SPen QuickTools 圆盘内部
  几何参数，Phase 709 SPen 边界）、`google_play_services_version`、
  `m3c_*`/`dialog_width_percentage`/`hide_password_duration` 等
  Compose/M3 平台键。
- `dimens.xml`：`qt_*` 全集 + `feature_note__quick_tool_*`
  （SPen Air Command 快捷工具盘尺寸，Phase 709 fail-closed）+
  `fastscroll_*`/`clock_face_*` 平台键；唯一可移植键为
  `app_widgets__widget_thumb_corner_radius`=6dp。
- `styles.xml`：`AppTheme`/`AppBaseTheme`/`app_widgets__ThemeSplash`
  + AppCompat/M3 内部样式——Android 主题系统无 HarmonyOS 对应物。
- `colors.xml`：除 12 个 `app_widgets__*` 外全部平台/M3 键；
  `app__shortcut_glyph`/`shortcut_icon_background` 引用
  `system_neutral1_*` Material You 动态取色——HarmonyOS 无该系统取色，
  快捷方式图标为静态资源（ADR-0669 已登记快捷方式面）。

## 决策

### 已移植（`app_widgets__*` 调色板/dimen 视觉对齐）

`colors.xml` 12 键 + `widget_thumb_corner_radius`=6dp + 各 widget
布局/drawable 结构映射到三张桌面卡片与缩略图卡片：

- `NewNoteCard`（`create_note_widget.xml`）：tile `#ecf2ff` r20
  （`widget_tile_bg_note`）；左上标签 `#171a20`
  （`widget_create_label`）；左下 40×40 r12 主色钮 `#4278ff`
  （`widget_button_bg_note`）内嵌白 `widget_add`「+」SVG
  （`widget_on_accent` 着色已固化进 SVG）。
- `NewRecordingCard`（`create_recording_widget.xml`）：同上结构，
  底 `#fff6ea` + 钮 `#ffa629`，图标换 `widget_record` mic 描边。
- `RecentNotesCard`/`FolderNotesCard`（`widget_notes_row.xml`）：
  行缩略图 r6 + 1px `#e8ebf0` 边框（`widget_thumb_border`；
  `widget_thumb_corner_radius`=6dp）；无图占位格 `#f6f6f8` 底 +
  `#c8cfdb` 着色图标（`placeholder_tile`/`placeholder_icon`）；
  标题 `#0c0d11`（`widget_text`）；行分隔线改每行无条件
  1px `#e8ebf0`（原版 `widget_row_divider` 内嵌每行）；
  卡片底 `#ffffff` r16（`widget_bg`）。
- `NoteThumbnailCard`（`widget_note_thumbnail.xml`）：占位
  `#f6f6f8` r16 + `#c8cfdb` 图标；缩略图改 `ImageFit.Fill`
  （原版 `scaleType="fitXY"` 拉伸）；卡片底 `#ffffff` r16。
- `widget_subject_bg`=#524278ff（`widget_subject_panel` 左侧
  主题面板底色）：Harmony 卡片为单栏结构无左侧面板，该色
  无挂载点——登记为布局结构差异。

### 边界登记

- 上述 arrays/bools/integers/dimens(`qt_*`/`quick_tool_*`)/styles
  全族：SPen SDK 内部（ADR-0672）、GMS/平台库内部、或 Android
  主题系统——均无 HarmonyOS 注入点，fail-closed。

## 后果

- 桌面卡片视觉与原版 widget 布局逐色对齐（tile/按钮/占位/分隔线/
  文本色 + 6dp 缩略图圆角）。
- 非 string 资源族全部归档：可移植项实现，其余边界登记。
