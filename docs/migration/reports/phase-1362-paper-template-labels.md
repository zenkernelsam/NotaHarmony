# Phase 1362 中文报告 — 纸张/模板选择器标签保真

## 修正

| 键 | 旧 | 新 | 原版键 |
|----|----|----|--------|
| template_lines | Lines | Rule | core_paper__rule |
| paper_size | Paper Size | Size | ui_templates__size |
| paper_size (zh) | 纸张尺寸 | 尺寸 | — |

横线模板原名 "Rule"（横线纸），非 "Lines"；尺寸区段原名 "Size"，非 "Paper Size"。
zh `template_lines`="横线" 对 "Rule"（横线纸）语义正确，不改。

## 刻意不改

- `template_spacing_level`="Spacing %d"：Harmony 泛化为任意模板间距滑杆；
  原版只有 grid 专用的 "Grid spacing: %1$d"，通用标签更稳。
- `template_favorite`/`unfavorite`：Harmony 用作无障碍描述（accessibilityText），
  描述性措辞优于原版按钮短标签。
- `paper_template`/`paper_color`：原版无对应区段键。

## 验证

`d02-paper-template-labels.mjs` **10/10** 绿。两 JSON 有效，单行格式保持。
