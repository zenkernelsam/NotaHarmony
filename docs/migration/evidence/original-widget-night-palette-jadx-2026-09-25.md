# 原版 values-night widget 暗色色板证据（decompiled_1.0.3）

日期：2026-09-25。`resources/res/values-night/colors.xml`（41 行）。

## widget 色键夜值对照（colors.xml → colors-night）

| 键 | 昼值（values/colors.xml） | 夜值（values-night/colors.xml） |
|---|---|---|
| `app_widgets__widget_bg` | `#ffffff` | `#1c1d22` |
| `app_widgets__widget_create_label` | `#171a20` | `#ffffff` |
| `app_widgets__widget_divider` | `#e8ebf0` | `#404856` |
| `app_widgets__widget_note_button` | `#4278ff` | `#5ba8f5` |
| `app_widgets__widget_note_tile_bg` | `#ecf2ff` | `#122231` |
| `app_widgets__widget_on_accent` | `#ffffff` | `#0c0d11` |
| `app_widgets__widget_placeholder_bg` | `#f6f6f8` | `#1f242b` |
| `app_widgets__widget_placeholder_icon` | `#c8cfdb` | `#616b7d` |
| `app_widgets__widget_recording_button` | `#ffa629` | **无夜键 → 回退昼值** |
| `app_widgets__widget_recording_tile_bg` | `#fff6ea` | `#332108` |
| `app_widgets__widget_subject_bg` | `#524278ff` | `#525ba8f5` |
| `app_widgets__widget_text` | `#0c0d11` | `#ffffff` |

原版语义：`widget_on_accent` 夜间翻转为 `#0c0d11`——即
add/record 矢量图标在夜间被 `note_button #5ba8f5`/
`recording_button #ffa629`（无夜键保持昼橙）浅色钮上以
深色着色（tinted vector，非烘焙白色）。

## values-night 其余键（非 widget）

`app__shortcut_glyph`/`shortcut_icon_background`（shortcut 自适应
图标的 Material You 取色，Harmony shortcut_*.svg 为静态媒体）、
`mini_setting_*`/`setting_*`/`setting_qt_*`/`component_common`
（SPen QuickTools/设置面板内部件——SPen 边界，ADR-0672/Phase 709）。
`color-night/material_timepicker_clockface.xml`、`values-night/
styles.xml`（12 行，M3 覆盖）为库件。

## Harmony 侧落点

- `note/src/main/resources/base/element/color.json`：新增 12 键
  （含昼值 `widget_recording_button`，无夜 twin 原版语义=回退）。
- `note/src/main/resources/dark/element/color.json`：新增 11 夜值。
- 5 张 form 卡片（NewNote/NewRecording/RecentNotes/FolderNotes/
  NoteThumbnailCard）硬编码 hex 全部改挂 `$r('app.color.
  app_widgets__widget_*')`；两张创建卡的 add/record SVG 增
  `.fillColor($r('app.color.app_widgets__widget_on_accent'))`
  对齐 tinted-vector 语义（夜态图标翻深色）。
- Phase 726 的昼值视觉对齐由此提升为昼夜双态对齐。
