# Phase 1386 修复报告 — 画笔样式选项 brushstyle 波形样张

## 目标

编辑器画笔样式选择器（`StyleButton`/`SelectionStyleButton`）此前以文本标签
（"Mono/Taper/Dash/Dots"）呈现，与原版不符。本阶段对照 `decompiled_1.0.3`，恢复为
原版的 **`brushstyle` 波形样张** —— 每个选项显示一条以该样式绘制的 44×24 波浪线。

## 原版行为

`x4j` 的样式选项是图标按钮：painter 取 `ui_tools__brushstyle_{mono,taper,dashed,dotted}`
（等粗/渐细/虚线/点状波形），样式名仅作无障碍描述。mono 为 stroked 开放波形，
其余为 filled 闭合波形，`y31` 序号与 `BrushStyle` 序号一致。

## Harmony 实现

- 新增 `BrushStyleGlyphs.ets`：4 个波形样张 `pathData`（`_gen_brushstyles.cjs` 提取，
  mono `stroked`、taper/dash/dot `filled`，viewport 44×24）。
- `brushStyleGlyph(style)` 映射 + `@Builder BrushStyleGlyphView(style, color)`：
  `stroked` 走 `.stroke`、否则 `.fill`，44×24 → 40×22。
- `StyleButton`/`SelectionStyleButton`：`Button(label)` → `Button(){glyph}`；
  选中态 `onAccent`/`textPrimary`、accent/control 底色、taper 门控、
  `setBrushStyle`/`onSelectionStyle` 不变；`.accessibilityText(label)` 保留样式名。

## 验收

| 项 | 结果 |
|----|------|
| 原版证据 | x4j + 4 个 brushstyle drawable 提取 ✅ |
| Replay fixture | `d02-original-brush-style-glyphs.mjs` 23/23 ✅ |
| `note@default` 构建 | 成功 ✅ |
| `note@ohosTest` clean 构建 | 成功 ✅ |
| 全量 Replay 基线 | 1239/1239 ✅ |

## 备注

此阶段与 Phase 1384（宽度按钮 strokeindicator）、1385（宽度槽位厚度样张）共同收齐
画笔控件的原版视觉语义：宽度按钮显样式×档位字形，宽度槽位显厚度样张，样式选项显
笔画波形样张，数值/名称均由无障碍文本承载。
