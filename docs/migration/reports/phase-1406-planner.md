# Phase 1406 报告 — 计划本（Academic Planner）

## 范围

原版 getting-started 面 "Planners" 特性端到端落地：bundled
`academic_planner_2026_2027` PDF（周一/周日两个变体）+ 四款封面
webp + 配置屏（周起点分段 + 封面格 + Create）+ 导入物化 +
封面持久化 + 库卡片封面缩略图。

## 原版证据

- `x1d`/`e2d`/`y1d`：Planner / WeekStart / Cover 枚举
  （`decompiled_1.4.2/sources/defpackage/`）。
- `a2d`：资产路径 `planners/academic_planner_2026_2027-<seg>.pdf`；
  `w95(case3)` 封面候选池谓词；走通用导入管线。
- `d2d`：默认构造 = 首封面 + MONDAY。
- `hel`/`l19`/`x2n`：分区 cell + sheet 内双模态配置屏 +
  wuh.CREATE CTA。
- `fel`/`kan`：模态进度 + 失败 snackbar。
- 资产：`assets/planners/*.pdf` × 2、`drawable-nodpi/ui_planners__
  cover_*_{0..3}.webp` × 4。

## Harmony 落点

- `rawfile/planners/`：6 资产（SHA-256 与原版一致）。
- `PlannerCatalog`：x1d/e2d/y1d 目录等价 + 默认 MONDAY。
- `NoteCoverCatalog`：`kind` 判别 + `PLANNER_COVER_PRESETS` +
  `findAnyNoteCover`（库缩略图并集）+ `loadImageCoverThumb`
  （webp ImageSource 解码）。
- `LibraryPage`：HomeContent "Planners" 分区卡 +
  `PlannerConfigSheet`（返回 + 周起点分段 + 封面格 + Create）+
  `createPlannerNote`（导入 → `cover_preset=planner_<idx>` → 打开）。
- `NoteImporter.importBundledPdfFromBytes` 公共薄封装。
- en/zh 字符串 11 键。

## 差异登记（ADR-1342）

- 宿主：原版 getting-started 面 → Harmony 库 Home 尾部；
  配置屏原版嵌模板 sheet → Harmony 独立 bindSheet。
- 封面赋经原版 w95 谓词筛池 → Harmony 创建后显式
  `setNoteCoverPreset`。
- onboarding 营销卡（`academic_planner_onboarding_*`）不引入。
- `planner_*` 封面不进 NoteCoverSheet 选择器（原版选择器同样
  只列 iw2 十款）。

## 验证

- Replay fixture `d02-original-planner.mjs`：86 断言绿；
  `d02-original-note-cover-presets.mjs` 一处随渲染路径改名更新。
- `note@default` 与 clean `note@ohosTest` HAP 构建通过。
- 全量 Desktop Replay 基线：1258/1258。
