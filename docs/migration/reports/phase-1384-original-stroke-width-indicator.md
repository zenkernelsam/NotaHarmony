# Phase 1384 修复报告 — 宽度按钮 strokeindicator 描边字形

## 目标

编辑器工具栏「粗细按钮」此前把宽度数值直接渲染为文本，与原版行为不符。本阶段对照
`decompiled_1.0.3`，恢复为原版的 **strokeindicator 描边字形**：一枚同时编码
「画笔样式 × 宽度档位」的向量图标。

## 原版行为

原版宽度按钮不显示数字，而是绘制 `ui_tools__strokeindicator_<style>_size<N>` 向量
（`swd`/`x5f`/`z5c`）：

- **样式**：`y31` 序号 0=mono（等粗条）、1=taper（楔形）、2=dash（虚线）、3=dot（圆点），
  与 Harmony `BrushStyle` 序号一一对应。
- **档位**：`x5f.c` 用当前工具宽度预设数组（`w4g.a`）找最接近当前宽度的预设下标，
  三等分为 `SMALL/MEDIUM/LARGE` → `size1/2/3`。
- **渲染**：`z5c` 先画略大一圈的 `outline` 环（主题前景色），再叠 `fill` 内填充
  （画笔色），形成带描边的样式化笔画示意。

## Harmony 实现

- 新增 `note/src/main/ets/ui/components/StrokeIndicators.ets`：12 个字形的
  `fill`/`outline` `pathData`（`_gen_strokeind.cjs` 自 drawable 逐字提取，dash/dot 多子路径已拼接）。
- `EditorToolbar.ets`：
  - `strokeWidthTier()`：`widthWells` 最近预设三等分（x5f.c 移植）。
  - `strokeIndicatorKey()`：`BrushStyle` → `strokeind_<style>_<tier>`。
  - 宽度按钮 `Shape{Path(outline)→textPrimary, Path(fill)→colorToHex(sel?selectionColor:brushColor)}`，
    `viewPort 24×6` 渲染为 32×8，`.accessibilityText` 仍给数值文本。

## 验收

| 项 | 结果 |
|----|------|
| 原版证据 | swd/x5f/z5c/uwd/w4g + 24 drawable 提取 ✅ |
| Replay fixture | `d02-original-stroke-width-indicator.mjs` 28/28 ✅ |
| `note@default` 构建 | 成功 ✅ |
| `note@ohosTest` clean 构建 | 成功 ✅ |
| 全量 Replay 基线 | 1237/1237 ✅ |

## 备注

数值宽度改由无障碍文本与宽度滑杆承载 —— 与原版的「抽象档位字形 + 工具名无障碍标签」
语义一致，视觉不再暴露原始数字。这是继菜单图标化（1375–1383）之后的又一处
「文本占位 → 原版向量」复刻。
