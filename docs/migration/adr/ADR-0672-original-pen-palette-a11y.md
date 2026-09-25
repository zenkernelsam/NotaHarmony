# ADR-0672 pen 调色板色名 a11y + SPen SDK 资源边界登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：724
- 证据：`docs/migration/evidence/original-pen-palette-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-pen-palette-a11y.mjs`

## 背景

顶层（无 `__` 前缀）字符串审计收尾时发现两大残留簇：

1. `pen_palette_color_*`（≈150 键）+ `pen_swatch_color_*`（26 键）——
   原版调色板每个色点的命名 a11y 文案（Samsung SPen SDK
   `SpenColorSwatchUtil`/`SpenPenWidthMiniLayout` 内部资源，
   Notability 经 SPen setting view 暴露）。
2. `pen_string_*`（8 键）——SPen pen-width mini 布局标签
   （"Colour"/"Colour picker"/"Eyedropper tool"/"Fixed thickness"/
   "Variable thickness"/"Current %s"/"New %s"/","）。
3. `selected`/`state_*`/`switch_role`/`tab`/`template_percent` 等
   7 个 Compose Material3 组件内部 a11y 状态文案。

Harmony `ColorPicker` 自绘色点此前无任何 a11y 文案。

## 决策

### 已移植

- `ColorPicker.colorDot` 增加 `a11yName: Resource | null` 第三参；
  自由预设格子的 12 个色点按色相映射原版命名：
  black/gray/red/orange/yellow/green/turquoise/blue/purple/
  pink(swatch)/brown_sugar/white → `pen_palette_color_*` /
  `pen_swatch_color_pink` 同名资源（值逐字一致："Grey" 保留原版
  英式拼写）。
- 收藏色井（wells）持用户自定义色、无固定名——统一以
  `pen_string_color`（"Colour"）作通用 a11y 标签（原版 SPen 色井
  亦以色名朗读；非预设井给通用标签优于静默）。
- zh 资源同步 13 键。

### fail-closed / 平台边界

- `pen_string_color_picker`/`pen_string_spuit`/`pen_string_comma`/
  `pen_string_current_any`/`pen_string_new_any`/
  `pen_string_fixed_thickness`/`pen_string_variable_thickness`：
  全部是 `com.samsung.android.sdk.pen.setting` 内 SpenPenWidthMini
  布局/SpenColorSwatch 组件的内部文案——Harmony 工具栏粗细/取色
  面板为自绘组件（eyedropper 已有自有标签），SDK 级文案不逐项
  映射，随 Phase 709 SPen SDK 边界统一登记。
- `pen_palette_color_*` 其余 ≈138 键与 `pen_swatch_color_*` 其余
  25 键：原版调色板全集的色名表（SPen SDK swatch/palette 网格），
  Harmony 12 预设格只引用语义等价子集；全集属 SDK 资源表登记，
  不逐个搬运未用色名。
- `selected`/`state_empty`/`state_off`/`state_on`/`switch_role`/`tab`/
  `template_percent`：Compose Material3 组件内部 a11y 文案
  （`pyi.java` 等 androidX 合成），ArkUI 自带组件框架已内置等效
  朗读体系，不映射。

## 影响

- `ColorPicker.ets`：+`presetColorName` 映射表、colorDot a11y 参数。
- 资源：en/zh 各 +13 键（12 色名 + `pen_string_color`）。
- 屏幕朗读下自由预设色点播报名字；收藏井播报 "Colour"。

## 验证

- `d02-original-pen-palette-a11y.mjs` 断言全绿。
- 全量 Desktop Replay 607+1；双 HAP 构建通过。
