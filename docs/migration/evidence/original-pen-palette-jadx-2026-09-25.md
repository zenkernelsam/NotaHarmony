# 原版证据：pen 调色板/SPen SDK 字符串 — JADX 静态审计（2026-09-25）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
（JADX 反编译 Notability 1.0.3，只读证据）

## 1. 归属

`pen_palette_color_*`（≈150）与 `pen_swatch_color_*`（26）的唯一
非 R.java 引用为：

```text
sources/com/samsung/android/sdk/pen/setting/color/SpenColorSwatchUtil.java
sources/com/samsung/android/sdk/pen/setting/handwriting/SpenPenWidthMiniLayout.java
```

即 Samsung SPen SDK 的 `setting.color`/`setting.handwriting` 组件
内部资源——Notability 启用 SPen pen-setting view 时由 SDK 渲染
swatch 网格并朗读 `getColorName(row, column)` 色名。

`pen_string_*`（8 键）同属 SPen SDK（pen-width mini 布局：
"Colour"、"Colour picker"、"Eyedropper tool"、
"Fixed thickness"/"Variable thickness"、"Current %s"/"New %s"）。

## 2. 本 phase 引用的逐字值

```text
pen_palette_color_black        Black
pen_palette_color_gray         Grey
pen_palette_color_red          Red
pen_palette_color_orange       Orange
pen_palette_color_yellow       Yellow
pen_palette_color_green        Green
pen_palette_color_turquoise    Turquoise
pen_palette_color_blue         Blue
pen_palette_color_purple       Purple
pen_swatch_color_pink          Pink
pen_palette_color_brown_sugar  Brown sugar
pen_palette_color_white        White
pen_string_color               Colour
```

映射：Harmony `presetColors` 12 项按色相对应（灰=Grey 原版英式、
青=Turquoise、粉=swatch_color_pink、棕=Brown sugar）。非预设色
（收藏井自定义值）以 `pen_string_color` 作通用标签。

## 3. Compose/Material3 内部件

`selected`/`state_empty`/`state_off`/`state_on`/`switch_role`/`tab`/
`template_percent` 为 androidx.compose 组件内 a11y 状态文案
（`pyi.java` 等合成代码引用）——平台库内部，非 Notability 表面；
ArkUI 有等效组件朗读体系，不映射。

## 4. 结论

- 12 预设色点名 + 通用 Colour 标签 → Harmony `colorDot` a11y。
- 其余 `pen_*`（≈170 键）与 M3 内部件随 SPen SDK / 平台边界
  登记（ADR-0672）。
