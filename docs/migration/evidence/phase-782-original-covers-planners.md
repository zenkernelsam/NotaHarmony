# Phase 782 证据：原版 1.4.2 封面/计划本选择器面

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2` strings.xml（`ui_notecovers__*`/
`ui_planners__*`/`ui_notedefaults__*`/`feature_note_ruler__*`）；
1.0.3 对照。
Replay：`docs/migration/replays/d02-original-covers-planners.mjs`
ADR：`ADR-0726-original-covers-planners.md`
上游：Phase 761（papertemplates 资产）、Phase 763（covers 资产）

## 1. 封面预设面（ui_notecovers__）

10 个具名封面预设：`preset_{blue,blue_journal,brown,
logo_pattern,maroon,orange,purple_journal,sage,stickers,yellow}`
（Plain/Journal/Minimalist/Logo/Simple/Stickers 显示名）+
通用 cancel/done——对应 Phase 763 登记的 `covers/` 10 份 PDF。
1.0.3 无任何 `ui_notecovers__` 键。

## 2. 计划本面（ui_planners__）

- 4 封面样式：`cover_{arches,lattice,pinstripe,scallop}`。
- `planner_academic_2026_2027`（"2026–2027 Academic Planner"）
  ——年度学术计划本为内置命名模板（对应 Phase 761
  papertemplates 包内的 planner 族包）。
- `week_start_{monday,sunday}`——周起始偏好项。
- `planners` 入口名。
1.0.3 无任何 `ui_planners__` 键。

## 3. 配套小面

- `ui_notedefaults__default_note_title_fallback`="Note"——
  配合 Phase 780 标题模板族的兜底值。
- `feature_note_ruler__{angle_label,angle_measure_label}`
  （%d° / Δ%d°）——1.0.3 已有 `ui_tools__ruler`+ruler_units
  设置；1.4.2 仅增角度读数标签（已有尺功能的小增量）。

## 4. Harmony 现状

- 无封面选择器/计划本面（grep "cover/Planner" 命中均为
  HandwritingConversionPlanner 等同名干扰）。
- 尺子设置已有（ruler_units 族已移植）；角度读数为增量。

## 5. 分类结论

- 封面选择器（10 预设+封面 PDF 资产）：版本差·本地候选。
- 计划本模板 + week-start：版本差·本地候选（数据驱动）。
- 尺子角度读数：小增量版本差。
- 标题兜底值：随 Phase 780 族登记。
