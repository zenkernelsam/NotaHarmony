# Phase 1427 证据：资源前缀扫描收口（pen_palette/ui_templates/vendored 族裁决）

## 扫描方法

对 `resources/res/values/strings.xml` 全量键按前缀归组，逐一核对 Harmony
覆盖状态。此前各 Phase 已裁决 feature_settings/note/library/learn/paywall、
stickers、login、support、transcription、widgets、fileimport、emojipicker、
permissions、core_paper、ui_share、ui_tools 等大轴。本期收口剩余族。

## `pen_palette_*` / `pen_swatch_*` / `pen_string_*`（约 204 键）

- 消费方全部位于 `com.samsung.android.sdk.pen.*`（SpenColorSwatchUtil、
  SpenPaletteColorHelper、SpenQTColorPickerViewCore）——三星 S Pen SDK
  随包私有调色板/快速工具，非一版 UI 源码。
- Harmony 已按同名键移植**预设色井 a11y 子集**（`ColorPicker.ets:34-48`，
  pen_palette_color_black/gray/red/orange/yellow/green/turquoise/blue/
  purple/brown_sugar/white + pen_swatch_color_pink）。
- 其余 158+ 命名色片仅出现在 vendored SDK 调色板内，Harmony 色板走自有
  预设井+取色器 → 剩余键 fail-closed（无宿主，非缺口）。

## `ui_templates__*`（59 键）

| 子面 | 原版宿主 | Harmony 裁决 |
|------|----------|--------------|
| bundled 图库（presets/recents/favorites/类别） | `qia` 区块 | 已移植 `PaperTemplateGallery` |
| Gallery 搜索框 + 翻页/重试 | `xcm`（onGalleryQueryChange/onLoadMoreGalleryTemplates，rsh 接口=远端契约） | **fail-closed：远端模板服务** |
| My Templates 增/删/改名/save_as_template | `cwa`/`l65`/`kf2`（rd5 InternalUserOnly 门控） | **fail-closed：原版未发布给用户** |
| 多页模板 select_pages（`olm.a`）/all_pages | 仅远端 Gallery 包详情页可达 | **fail-closed：随远端服务** |
| repeat_template / interactive_template | 仅 R.java 引用 | 1.4.2 死字符串，无需处理 |
| set_as_default / orientation / size / grid_spacing / background_color / preview / go_to / current / new | 默认模板设置与详情页 | 已移植（default_template_*、template_spacing_level 等） |

## `ui_notecovers__*`（14 键）

`iw2` 10 preset + `ebn` 预览卡 + Cancel/Done —— 已移植为
`NoteCoverSheet`（ADR-1341），preset 键 note_cover_preset_* 全量在。

## `ui_papertemplates__*`（15 键）

类别键（academic/creative/notepads/planning/self_care）已移植为
`paper_templates_cat_*`。

## vendored 字符串族（无宿主）

`m3c_`（Material3 Compose）、`mtrl_`/`material_`、`abc_`/`androidx_`、
`call_notification_*`（AndroidX core）、`ids_`/`dream_`/`mids_`（三星
SDK）、`firebase_*`/`google_*`（GMS）、`common_`/`generic_`/`nav_`/
`notification_`/`preference_`/`exo_`/`fk_`/`tooltip_`/`switch_`/`tab_`/
`state_`/`default_`/`close_`/`navigation_menu`/`in_progress`/
`indeterminate`/`not_selected`/`selected` —— 均为随包库内部资源，
无应用层语义，整体 fail-closed。

## 回放

`d02-original-resource-prefix-sweep.mjs`（9 项断言）钉住：bundled 图库
与封面 preset 移植、pen_palette a11y 子集同名键、无远端 Gallery 搜索、
无自定义模板管理面、无多页 select_pages 面、ADR-1362 裁决文书。
