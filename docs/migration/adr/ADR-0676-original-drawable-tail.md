# ADR-0676 drawable/mipmap/anim/layout 族收口登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：728
- 证据：`docs/migration/evidence/original-drawable-tail-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-drawable-tail.mjs`

## 背景

非字符串资源审计的末族：`res/drawable*`（482 件）、`res/mipmap-*`、
`res/{anim,animator,interpolator,color}`、`res/layout*` 应用级键。

## 决策

### 已移植/程序化等价（无需逐文件搬运）

- `app_widgets__*`（19 件布局/drawable）——Phase 726 已逐色逐形映射。
- `app__shortcut_*`（6 件）——Phase 721，`shortcut_*.svg` 媒体在位。
- `core_paper__paper*.webp`（15 件）——`rawfile/` 已内置。
- `ui_tools__tape_pattern_*`（9）+ `_laser_*`（2）——
  `TapePatternPicker`/`OriginalLaserPointer` 程序化渲染（等价或更优）。
- `ui_renderer__pencil_splat.png`——`PencilSplatGenerator` 程序化生成。

### 文本化惯例（不搬图标文件，既有决策延续）

`ui_designsystem__*`（216 图标）、`ui_text__*__medium`（17）、
`ui_tools__brushstyle_*/strokeindicator_*`（28）、
`feature_note__selection_menu_*`（9）、`feature_note_toolbox__*`（5）、
`feature_library__*`（4）：Harmony 对应用面以文本标签按钮/菜单承载
（ADR-0668 先例——原版 icon 节点的 a11y 文案已在文本节点等价登记）。

### 边界登记

- `feature_login__*`（8）+ `feature_settings__` 社交图标行（7）：
  登录面/About 社交区——登录面 fail-closed（ADR-0662），About 区
  社交外链行随设置面缺位登记（Harmony 设置无 About 子页）。
- `feature_note__hwr_toggle`/`youtube`：HWR/YouTube 面边界
  （ADR-0670/0651）。
- `spen_*`/`qt_*`/`setting_*`/`note_handwriting_*`/`pressure_*` 等
  ≈140 件：SPen SDK/QuickTools 内部件（ADR-0672、Phase 709）。
- `anim`/`animator`/`interpolator`/`color`/`mtrl`/`abc_`/`exo_`/
  `sesl`/`mipmap` 平台件：Android 组件库内部资源，无 Harmony 挂载点。
- `feature_note__quick_tool_center.xml` 等 SPen 布局：Phase 709 边界。
- `values-*` 限定符机制：Harmony `resources/dark/` + 断点等价，
  不做逐文件对照。

## 后果

`res/` 全部资源族审计闭合（strings/plurals/arrays/bools/integers/
dimens/colors/styles/font/assets/drawable/mipmap/anim/animator/
interpolator/color/layout/xml/values-* 均有归属）。剩余审计向量：
manifest 组件级与服务级行为面（既有 ADR 已覆盖深链/分享/卡片/
fileshare），原始 JADX 逻辑面长尾。
