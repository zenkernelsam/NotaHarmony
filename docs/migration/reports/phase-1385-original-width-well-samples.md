# Phase 1385 修复报告 — 宽度预设槽位笔画厚度样张

## 目标

`WidthSlider` 预设槽位此前以 `Text(width)` 数字徽章呈现，与原版不符。本阶段对照
`decompiled_1.0.3`，恢复为原版的「笔画厚度样张」—— 槽位显示一条厚度随预设宽度
变化的横向笔画，而非数字。

## 原版行为

- 预设槽位是 `width_view` `ImageView`（`setting_pen_width_mini_layout`），由
  S-Pen SDK（`SpenSettingQTAttributesLayout`/`SpenPenWidthMiniLayout`）填入厚度样张，
  槽位本身不含数字文本。
- 预设槽位一字排开，厚薄直观可比；点击槽位即选用该宽度。
- 数字宽度由独立的 `ui_tools__width` "Width: %1$d" 读数显示（滑杆上方，Harmony 已保留）。

## Harmony 实现

- `wellSampleHeight(width) = clamp(width, 2, 16)`：预设宽度线性映射到 2–16px 条厚。
- 槽位内容 `Text(width)` → `Row{横向圆角条 height=wellSampleHeight, fill=brushColor}`，
  外层固定 36×28 槽位卡 + 原选中态 accent 边框。
- `.accessibilityText(width.toString())` 保留预设数值给无障碍/读屏；
  `setBrushWidth(width, index)` 与 photoImportLease 门控不变。

## 验收

| 项 | 结果 |
|----|------|
| 原版证据 | setting_pen_width_mini_layout + SpenPenWidthMiniLayout + yed ✅ |
| Replay fixture | `d02-original-width-well-samples.mjs` 13/13 ✅ |
| `note@default` 构建 | 成功 ✅ |
| `note@ohosTest` clean 构建 | 成功 ✅ |
| 全量 Replay 基线 | 1238/1238 ✅ |

## 备注

S-Pen SDK 的样张像素为专有内部实现，Harmony 采用等价的横向圆角条表达同一
「厚度样张」语义（受控适配）。此阶段与 Phase 1384（宽度按钮 strokeindicator 字形）
共同收齐了宽度控件的原版视觉语义：按钮显样式×档位字形，槽位显厚度样张，
数值由无障碍文本与 "Width: N" 读数承载。
