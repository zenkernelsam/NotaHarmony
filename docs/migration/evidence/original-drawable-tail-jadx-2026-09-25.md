# 原版 drawable/mipmap/anim/layout 族尾部证据（decompiled 1.0.3）

日期：2026-09-25。范围：`resources/res/{drawable,drawable-nodpi,mipmap-*,anim,animator,interpolator,color,layout,layout-*}`。

## 盘点（drawable+mipmap 共 482 件）

按前缀分桶：

| 桶 | 数量级 | 归属 |
|---|---|---|
| `ui_designsystem__*` 图标 | 216 | 逐面图标字模；Harmony 惯例=文本标签按钮+按需 SVG 媒体（ADR-0668 先例：icon 节点 a11y 文案无对应节点时登记）。 |
| `spen_*`/`qt_*`/`setting_*`/`note_handwriting_setting_color_01.webp` | ≈140 | SPen SDK 调色/笔触/快捷工具盘内部件——SPen 边界（ADR-0672、Phase 709）。 |
| `abc_`/`mtrl_`/`btn_*`/`exo_`/`common_`/`googleg*`/`sesl*`/`$avd*`/`ic_*` 库件 | ≈70 | AppCompat/M3/ExoPlayer/Play 库内部件——平台边界。 |
| `app_widgets__*` | 19 | Phase 726 已逐件映射（tile/按钮/边框/占位/subject 面板）。 |
| `app__shortcut_*` | 6 | 桌面快捷方式图标（Phase 721；Harmony `shortcut_*.svg` 已置）。 |
| `core_paper__paper*.webp` | 15 | 纸张纹理——已拷入 `rawfile/`。 |
| `feature_login__*` | 8 | 登录面社会图标/插画（ADR-0662 边界）。 |
| `feature_settings__instagram/linkedin/tiktok/threads/youtube/star/checkmark*` | 7 | 原版 About 区社交图标行（g8.java case9-13 逐图标 `gvh.a`）——About 面缺位边界（随 ADR-0673/0662 登记族）。 |
| `feature_note__selection_menu_*`（9） | 9 | 选区菜单图标——Harmony 菜单文本化（ADR-0645/0670 覆盖）。 |
| `feature_note__hwr_toggle`/`youtube`/`gif_attribution`/`checkmark`/`close`/`reset` | 6 | HWR/YouTube 边界 + 通用字形（既有媒体承载）。 |
| `feature_note_toolbox__*` | 5 | 工具箱图标——Harmony 文本标签（ADR-0654 族覆盖）。 |
| `feature_library__*` | 4 | 库面图标（createnote/grid_view/importnewnote/notability_icon/templatenewnote）——Harmony 文本/现有媒体承载。 |
| `ui_tools__brushstyle_*` + `strokeindicator_*` | 28 | 笔刷样式/笔宽预览图标——Harmony 文本样式钮 + Width 步进（ADR-0668）。 |
| `ui_tools__tape_pattern_*` + `tape_conceal/reveal` | 11 | tape 图案样本——Harmony `TapePatternPicker` 程序化实时预览瓦片（等价且更优）。 |
| `ui_text__*__medium` | 17 | 文本格式图标——Harmony 文本菜单标签（Phase 719/ADR-0667）。 |
| `pressure_on/off` | 2 | 压感开关图标——Harmony 压感逻辑已移植，图标节点无对应。 |
| `_ui_designsystem__laser_*` | 2 | 激光笔纹理——Harmony `OriginalLaserPointer` 程序化渲染。 |
| `checkerboard_pattern`/`circle_shape`/`dialog_*`/`empty.xml`/`navigation_empty_icon`/`color_picker_icon_selector`/`selected_white`/`setting_mini_attr_*`/`ui_fileimport__docscan` | ≈20 | 通用/平台形状 + docscan 图标（VisionKit 面 ADR-0647）。 |
| `mipmap-*` | launcher icon | 已移植（`layered_image.json`/startIcon）。 |

## anim/animator/interpolator/color

- `anim/`、`animator/`、`interpolator/`：AppCompat/M3/SPen 内部动画
  资源（fragment 转场、checkbox/radio 描边动画、spen_recoil 等）——
  平台组件内部，无 Harmony 挂载点。
- `color/`（res/color selector）：M3 组件内部色彩选择器，平台内部。
- `layout/` 应用键仅剩 `feature_note__quick_tool_center.xml`（SPen
  快捷工具盘，Phase 709 边界）+ `setting_*`/`dialog_*`（SPen/平台）；
  `app_widgets__*` 布局已映射（Phase 726）。
- `values-*` 限定符目录（night/land/sw600dp/watch 等）为 Android
  资源限定机制——Harmony 以 `resources/dark/` + 断点机制等价，
  无逐文件对照义务。

## 结论

drawable/mipmap/anim/layout 族全部键有归属：已移植（widgets/
shortcuts/papers/media 对照）、程序化等价（tape/laser/pencil splat）、
文本化惯例（toolbox/selection/text-format 图标，ADR-0668 先例）、
边界（SPen/登录/About/YouTube/HWR/docscan）、平台内部件。
