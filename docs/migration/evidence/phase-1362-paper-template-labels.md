# Phase 1362 — 纸张/模板选择器标签保真

## 原版证据（strings.xml `core_paper__*`/`ui_templates__*`）

- `core_paper__rule` = `Rule`（横线模板显示名）
- `ui_templates__size` = `Size`（尺寸区段标签）
- `ui_templates__orientation` = `Orientation`
- `core_paper__plain/grid/dots` = `Plain`/`Grid`/`Dots`
- `core_paper__portrait/landscape` = `Portrait`/`Landscape`
- `ui_templates__grid_spacing` = `Grid spacing: %1$d`
- `ui_templates__favorite`/`unfavorite` = `Favorite`/`Unfavorite`

## 调用点核对

- `PageSettingsPanel.templateLabel`：`PaperTemplate.LINES`→`template_lines`，原值 `"Lines"`，
  原版为 `"Rule"`（横线纸）。→ 改 `template_lines`=`"Rule"`。
- `PageSettingsPanel:467` 尺寸区段标题 `paper_size`，原值 `"Paper Size"`，原版 `ui_templates__size`=`"Size"`。
  → 改 `paper_size`=`"Size"`；zh `纸张尺寸`→`尺寸`。

## 刻意不改

- `template_spacing_level`="Spacing %d" — Harmony 用于**任意**模板的间距滑杆
  （`spacingIndex(template)` 泛化），原版仅有 grid 专用的 `grid_spacing`。通用标签更稳。
- `template_favorite`/`unfavorite` — Harmony 用作 `accessibilityText`（无障碍描述），
  描述性措辞优于原版按钮短标签 `Favorite`/`Unfavorite`。
- `paper_template`/`paper_color` — 原版 `core_paper__`/`ui_templates__` 无对应区段键，
  属 Harmony 自定义区段标签。
- `template_lines` zh `横线` — `"Rule"`（横线纸）的正确中文即"横线"，不改。

## 验证

`d02-paper-template-labels.mjs`：10/10（含 plain/grid/dots/portrait/landscape/orientation 回归守卫）。
