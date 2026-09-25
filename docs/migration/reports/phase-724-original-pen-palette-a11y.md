# Phase 724 中文报告：pen 调色板色名 a11y + SPen SDK 资源边界

## 范围

无 `__` 前缀的顶层字符串审计收尾：`pen_palette_color_*`（≈150）、
`pen_swatch_color_*`（26）、`pen_string_*`（8）与 7 个 M3 内部 a11y
件。其余顶层键已在早前 phase 覆盖或为库级噪音（abc_/common_/
exo_/dream_/mids_ 等）。

## 原版证据

见 `docs/migration/evidence/original-pen-palette-jadx-2026-09-25.md`：

- `pen_palette_color_*`/`pen_swatch_color_*`/`pen_string_*` 均为
  Samsung SPen SDK 组件内部资源
  （`SpenColorSwatchUtil`/`SpenPenWidthMiniLayout`），由 SPen
  pen-setting view 渲染色名朗读。
- `selected`/`state_*`/`switch_role`/`tab`/`template_percent` 为
  Compose Material3 组件内部 a11y 状态文案。

## 变更

- `ColorPicker.ets`：新增 `presetColorName(color)` —— 12 自由预设
  色点按色相映射原版色名（black/gray/red/orange/yellow/green/
  turquoise/blue/purple/pink/brown_sugar/white，en 值逐字一致，
  "Grey" 保留原版英式拼写）；`colorDot` 增 `a11yName` 参数挂
  `accessibilityText`；自由预设格子传色名，收藏井以
  `pen_string_color`（"Colour"）作通用 a11y 标签。
- 资源：en/zh 各 +13 键。

## fail-closed 登记（ADR-0672）

- `pen_string_color_picker`/`spuit`/`comma`/`current_any`/`new_any`/
  `fixed_thickness`/`variable_thickness`：SPen SDK pen-width mini
  布局内部文案，随 Phase 709 SPen 边界登记。
- `pen_palette_color_*`/`pen_swatch_color_*` 其余 ≈163 键：SPen
  swatch/palette 全集色名表，Harmony 12 预设仅引用等价子集。
- M3 内部 a11y 件：平台库内部，ArkUI 自带等效朗读。

## 验证

- 新增 Replay：`d02-original-pen-palette-a11y.mjs`（全绿）。
- 全量 Desktop Replay：608/608 全绿。
- `note@default` / `note@ohosTest` 双 HAP 构建通过。

## 涉及文件

- `note/src/main/ets/ui/components/ColorPicker.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/adr/ADR-0672-original-pen-palette-a11y.md`
- `docs/migration/evidence/original-pen-palette-jadx-2026-09-25.md`
- `docs/migration/replays/d02-original-pen-palette-a11y.mjs`
