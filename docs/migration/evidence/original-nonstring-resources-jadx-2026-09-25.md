# 原版非 string 资源尾部证据（JADX 1.0.3 decompiled）

日期：2026-09-25。来源：`decompiled_1.0.3/resources/res/values/{arrays,bools,integers,dimens,styles,colors}.xml` + `res/{layout,drawable}/app_widgets__*`。

## app_widgets__ 调色板（colors.xml 逐字）

| key | 值 |
|---|---|
| widget_bg | #ffffff |
| widget_create_label | #171a20 |
| widget_divider | #e8ebf0 |
| widget_note_button | #4278ff |
| widget_note_tile_bg | #ecf2ff |
| widget_on_accent | #ffffff |
| widget_placeholder_bg | #f6f6f8 |
| widget_placeholder_icon | #c8cfdb |
| widget_recording_button | #ffa629 |
| widget_recording_tile_bg | #fff6ea |
| widget_subject_bg | #524278ff |
| widget_text | #0c0d11 |

`app__shortcut_glyph`=`system_neutral1_900`、`app__shortcut_icon_background`=
`system_neutral1_50`（Material You 动态取色，平台边界）。

## dimens.xml 唯一应用键

```xml
<dimen name="app_widgets__widget_thumb_corner_radius">6dp</dimen>
```

消费点 `WidgetImageProvider.java:106`——`dzi.a(context, file, 48dp,
widget_thumb_corner_radius)` 生成圆角缩略位图。Harmony 侧
`Image.borderRadius` + `widget_thumb_border`（#f6f6f8 底 +
1px #e8ebf0 描边 + r6）等价。

## 关键布局结构

`app_widgets__create_note_widget.xml`：
- 根 RelativeLayout 背景 `widget_tile_bg_note`（drawable=矩形 solid
  `widget_note_tile_bg` #ecf2ff + corners 20dp）
- 左上 ImageView 标签（tint `widget_create_label` #171a20，marginTop/Start 12dp）
- 左下 FrameLayout 40dp×40dp（背景 `widget_button_bg_note`=solid #4278ff
  + r12，elevation 4dp），内嵌 22dp `widget_add` + 图标
  tint `widget_on_accent` #ffffff

`create_recording_widget.xml` 同构：`tile_bg_recording` #fff6ea /
`button_bg_recording` #ffa629 / `widget_record` mic 图标。

`widget_notes_row.xml`：行 = `widget_thumb_border` 包裹缩略图
（#f6f6f8 底 + 1dp #e8ebf0 描边 + r6）→ 标题 ImageView
（tint `widget_text` #0c0d11）→ 每行末尾 `widget_row_divider`
1dp #e8ebf0（无条件，含末行）。占位图 `page_new_note_fill` tint
`widget_placeholder_icon` #c8cfdb。

`widget_notes.xml`：根 `widget_bg`（#ffffff r16）；左 116dp
`widget_subject_panel`（solid `widget_subject_bg` #524278ff r12）
含头部 glyph + 40dp `widget_button_bg_note` 创建钮。

`widget_note_thumbnail.xml`：根 `widget_bg`；ImageView
`scaleType="fitXY"`（拉伸充满）；占位 ImageView 背景
`widget_placeholder_tile`（#f6f6f8 r16）+ `page_new_note_fill`
tint #c8cfdb。

`widget_add` 向量路径：`M11,5h2v14h-2zM5,11h14v2h-14z`（+）。
`widget_record`：mic 描边向量（strokeWidth 1.25）。

## 平台/SDK 键（不移植）

- arrays.xml：79 键 `spen_*`（SPen SDK `SpenSettingPenLayout`/
  `SpenColorSwatchUtil` 内部调色板数组）+ `feature_learn__chat_card_headers`
  （Learn AI 建议卡，账号/AI 后端边界）。
- bools.xml：`firebase_*`、`workmanager_test_configuration`、
  `enable_system_foreground_service_default` 等库内部。
- integers.xml：`qt_*`/`setting_qt_*`（SPen QuickTools 圆盘几何）、
  `google_play_services_version`、`m3c_window_layout_in_display_cutout_mode`、
  `dialog_width_percentage`、`hide/show_password_duration`。
- dimens.xml：`qt_*` 全集、`feature_note__quick_tool_center_size`/
  `edge_size`（SPen 快捷工具盘，Phase 709 边界）、`fastscroll_*`、
  `clock_face_margin_start`。
- styles.xml：`AppTheme`/`AppBaseTheme`/`app_widgets__ThemeSplash` +
  AppCompat/M3/`Sesl*` 内部样式（Android 主题系统，无 Harmony 对应物）。
