# 原版 1.4.2 内置纸张模板包格式登记（Phase 761 证据）

> 日期：2026-09-29（Asia/Shanghai）
> 证据源：`decompiled_1.4.2/resources/assets/papertemplates/`（1.0.3 无此目录）
> 性质：1.4.2 版本差证据登记（ADR-0708 处置框架下"版本差·待审"细化）；无 Harmony 代码变更。

## 一、包内结构

每个模板目录 `<dir>/` 含：

- `metadata.json` —— 包清单（schema 见下）；
- `{DisplayPrefix}_{Size}_{hexColor}_{orientation}.pdf` —— 每个
  尺寸×颜色×方向组合一个 PDF 纸张底板（如 `Cornell_A3_f8f1bf_landscape.pdf`）；
- `thumb{,_black}{,_landscape}.{heic,png}` —— 缩略图混用 HEIC（49 件）
  与 PNG（18 件）；命名维度为浅色/深色×方向（部分包仅单 Thumb，
  共 1~4 件，如 cornell 为 PNG 双方向、assignment_planner 为 HEIC 双主题）。

`metadata.json` schema（以 cornell 为规范例）：

```json
{
  "uuid": "9593C04C-E38E-4510-BE1F-F07A754A226D",
  "name": "Cornell Note",
  "paperSizes": ["a3", "a4", "a5", "letter", "tabloid", "legal"],
  "defaultPaperSize": "letter",
  "colors": ["#ffffff", "#000000", "#f8f1bf"],
  "category": "notepads"
}
```

- `paperSizes` 值域：a3/a4/a5/letter/tabloid/legal（各包子集）；
- `colors` 为 hex 列表，PDF 文件名中的颜色段去掉 `#`；
- `category` 值域与字符串族 `ui_papertemplates__{academic,creative,
  notepads,planning,self_care}` 一一对应；
- 组合数规则：PDF 数 = sizes × colors × 方向变体数；双方向包文件名带
  `_landscape/_portrait` 后缀（college_rule 6×3×2=36），单方向包不带
  方向段（isometic `Isometic_A4_000000.pdf` 2×2×1=4）。

## 二、35 包全量目录

| dir | name | category | sizes | colors | pdfs | thumbs |
|-----|------|----------|-------|--------|------|--------|
| assignment_planner | Assignment Planner | academic | 2 | 2 | 4 | 2 |
| college_rule | College Rule | notepads | 6 | 3 | 36 | 4 |
| cornell | Cornell Note | notepads | 6 | 3 | 36 | 2 |
| daily_goals | Daily Goals | selfCare | 2 | 1 | 2 | 1 |
| daily_gratitude | Daily Gratitude | selfCare | 2 | 1 | 2 | 1 |
| daily_itinerary | Daily Itinerary | planning | 1 | 2 | 2 | 2 |
| daily_journal | Daily Journal | selfCare | 2 | 1 | 2 | 1 |
| daily_planner | Daily Planner | planning | 2 | 2 | 4 | 2 |
| daily_tasks | Daily Tasks | selfCare | 2 | 1 | 2 | 1 |
| engineering_grid | Engineering Grid | notepads | 6 | 3 | 36 | 2 |
| finance | Monthly Finance Tracker | planning | 2 | 2 | 4 | 2 |
| goal_setting | Goal Setting | planning | 2 | 2 | 4 | 2 |
| habit_tracker | Habit Tracker | selfCare | 2 | 1 | 2 | 1 |
| hexagonal_grid | Hexagonal Grid | notepads | 6 | 3 | 36 | 2 |
| isometic | Isometric | notepads | 2 | 2 | 4 | 2 |
| manuscript | Manuscript | notepads | 6 | 3 | 36 | 4 |
| meal | Meal Planner | planning | 2 | 2 | 4 | 2 |
| mind_map | Mind Map | academic | 2 | 2 | 4 | 2 |
| mizige | Mizige | notepads | 6 | 3 | 36 | 2 |
| monthly_planner | Monthly Planner | planning | 2 | 2 | 4 | 2 |
| music_staves | Music Staves | creative | 6 | 2 | 4 | 2 |
| recipe | Recipe | creative | 2 | 2 | 4 | 2 |
| self_care_checklist | Self Care Checklist | selfCare | 2 | 1 | 2 | 1 |
| semester_overview | Semester Overview | academic | 2 | 2 | 4 | 2 |
| sleep_journal | Sleep Journal | selfCare | 2 | 1 | 2 | 1 |
| storyboard_4 | Storyboard (4) | creative | 2 | 2 | 4 | 2 |
| storyboard_6 | Storyboard (6) | creative | 2 | 2 | 4 | 2 |
| study_session_planner | Study Session Planner | academic | 2 | 2 | 4 | 2 |
| three_column | Three Column | notepads | 2 | 2 | 4 | 2 |
| tianzege | Tianzege | notepads | 6 | 3 | 36 | 2 |
| travel_journal | Travel Journal | planning | 1 | 2 | 2 | 2 |
| travel_planner | Travel Planner | planning | 1 | 2 | 2 | 2 |
| two_column | Two Column | notepads | 2 | 2 | 4 | 2 |
| weekly_planner | Weekly Planner | academic | 2 | 2 | 4 | 2 |
| weekly_planner_planning | Weekly Planner Planning | planning | 2 | 2 | 4 | 2 |

分类计数：notepads 10 / planning 9 / academic 5 / selfCare 6 / creative 5 = 35。

## 三、与 1.0.3 纸张体系的关系

1.0.3 的纸张为代码生成模板（PLAIN/LINES/GRID/DOTS + legacy 纹理 +
自定义颜色/间距 —— NotaHarmony `OriginalTemplatePickerState` 已等价移植）。
1.4.2 的 papertemplates 是**新形态**：整页 PDF 底板资产 + 声明式包清单，
属模板中心改版（`ui_templates__*`/`ui_papertemplates__*` 字符串族）的
资源底座，不取代 1.0.3 生成式纸张语义。

## 四、处置

- 资产形态纯本地（PDF + JSON + HEIC），理论可移植候选；
- 引入需另开 Phase 评估：Harmony PDF 底板渲染链、HEIC 解码
  （或转 PNG 重打包）、与 1.0.3 生成式纸张选择器的并存关系；
- 在 ADR-0708 框架下登记为"版本差·待审"，本阶段仅登记格式证据。
