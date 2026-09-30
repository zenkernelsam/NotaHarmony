# ADR-1303 — 纸张/模板选择器标签保真

## 状态

Accepted（已落地）。

## 决策

- `template_lines` `Lines`→`Rule`：原版 `core_paper__rule`="Rule"（横线纸模板名）。
- `paper_size` `Paper Size`→`Size`：原版 `ui_templates__size`="Size"（模板选择器尺寸区段）。
- zh `paper_size` `纸张尺寸`→`尺寸` 同步；zh `template_lines`="横线" 已是 "Rule" 正确译法，保留。

## 刻意不改

- `template_spacing_level`/`template_favorite`/`template_unfavorite`/`paper_template`/`paper_color`：
  泛化间距滑杆、无障碍描述、无对应原版区段键，保留更稳/描述性更优。

## 依据

- 证据：`docs/migration/evidence/phase-1362-paper-template-labels.md`
- Replay：`d02-paper-template-labels.mjs`（10/10）

## 后果

模板选择器标签与原版逐字对齐（Plain/Rule/Grid/Dots + Size/Orientation/Portrait/Landscape）。
