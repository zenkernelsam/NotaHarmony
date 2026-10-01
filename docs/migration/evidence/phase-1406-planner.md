# Phase 1406 — 原版计划本（Academic Planner）证据

## 原版证据（decompiled_1.4.2）

### 目录与资产

- `x1d.java` — Planner 枚举。1.4.2 仅 `ACADEMIC_2026_2027` 一项；
  `a()` 返回该计划本的 `y1d` 封面列表，`b()` 取首个封面（缺封面仅记
  `k47.h("planner academic_planner_2026_2027 has no covers")`）。
- `e2d.java` — `PlannerWeekStart{MONDAY(0), SUNDAY(1)}`；`F` 为 PDF
  文件名段（`monday_start`/`sunday_start`），`G` 为
  `ui_planners__week_start_*` 名字 res。
- `y1d.java` — `PlannerCover` 四款，枚举序
  `ACADEMIC_PINSTRIPE / ACADEMIC_LATTICE / ACADEMIC_SCALLOP /
  ACADEMIC_ARCHES`；`G` = `ui_planners__cover_academic_planner_
  2026_2027_<index>.webp` drawable，`H` = `ui_planners__cover_*`
  名字 res。
- `a2d.java` — `a(weekStart, cover, title)`：
  `bm1.r("planners/academic_planner_2026_2027-", e2d.F, ".pdf")` 拼
  资产路径；`zu2.n(str, ".pdf")` 生成 `<title>.pdf` 文件名；
  `w95(其它封面序号集合, case3)` 谓词把未选封面筛出候选池（等价于
  指定所选封面）；随后 `b.d(...)` 进通用 PDF→笔记导入管线，
  返回 `pg7`（成功 `tf7`）。埋点 `planner.id` /
  `planner.week_start`。
- `d2d.java` — `PlannerSelection{cover=y1d, weekStart=e2d}`；
  `d2d(y1d)` 默认构造 `weekStart = e2d.MONDAY`。
- `b13.java` — 创建协程：`dma.d(de0(dh7.PLANNER))` 推进度 →
  `a2d.a(...)` → `c13.d(...)` 物化并打开笔记。
- `hel.java` — `hel.c(x1d, onClick)`：getting-started 面 "Planners"
  分区 cell（预览 = `x1d.b().G` 首封面 drawable + 计划本标题）；
  `hel.b(e2d, y1d, onWeekStart, onCover)`：上半 `qmm.a(e2d.J,…)`
  周起点分段行 + 下半 `ne9.d` 封面格（`hel.d` cell = drawable +
  名字 + 选中态）；`hel.d`/`hel.a` 为通用图+标签 cell。
- `l19.java` / `x2n.java` — 模板 sheet 双模态：`d2d == null` →
  `x2n.j` 模板内容；`d2d != null` → `x2n.c(d2d, onWeekStart,
  onCover, onCreate, onBack…)` 计划本配置屏；底栏
  `x2n.f(wuh.CREATE,…)` = "Create"（`ui_templates__create`）。
- `a1n.java` — getting-started 面 LazyColumn：节头 + recents 网格
  + `f8m.d` "Planners" 节头 + 计划本行（`l19(list,…)` 逐 cell）。
- `fel.java` — 模态进度卡 `feature_library__creating_planner_note`
  "Creating your planner note"（`pr4.a(false,…)` 禁返回 +
  pointer-input 吞点击）。
- `kan.java` — 失败 snackbar `feature_library__planner_failed`
  "Couldn't create note from planner. Please try again."。
- `c13.java` — 物化/打开共用编排（含 `b2d` 进度槽）。
- 字符串：`ui_planners__planners`/`ui_planners__planner_academic_
  2026_2027`/`ui_planners__week_start_monday|sunday`/
  `ui_planners__cover_{arches,lattice,pinstripe,scallop}`/
  `ui_templates__create`；onboarding 卡文案
  `ui_designsystem__academic_planner_onboarding_*`。
- 资产：`resources/assets/planners/academic_planner_2026_2027-
  {monday,sunday}_start.pdf`（各约 2MB）；
  `resources/res/drawable-nodpi/ui_planners__cover_academic_planner_
  2026_2027_{0..3}.webp`。

## Harmony 落点

- 资产逐字节拷入 `note/src/main/resources/rawfile/planners/`
  （2 PDF + `cover_{0..3}.webp`，SHA-256 与原版一致）。
- `core/model/PlannerCatalog.ets` —
  `PlannerWeekStart{key,fileSegment,nameRes}`（e2d 序，默认 MONDAY =
  `PLANNER_DEFAULT_WEEK_START`，对应 `d2d(y1d)` 默认构造）、
  `PlannerCover{index,presetKey='planner_<index>',nameRes,
  rawfilePath}`（y1d 序）、`ACADEMIC_PLANNER`/`PLANNERS`（x1d 等价，
  `pdfPath()` = a2d 拼接）、`plannerDefaultCover`（x1d.b()）。
- `core/model/NoteCoverCatalog.ets` —
  `NoteCoverPreset.kind`（`'pdf' | 'image'`）+
  `PLANNER_COVER_PRESETS`（`planner_0..3` → `planners/cover_*.webp`）+
  `findAnyNoteCover`（库缩略图渲染的并集查找；选择器仍
  `findNoteCoverPreset` 只列 iw2 十款）+ `loadImageCoverThumb`
  （webp → `image.createImageSource` → PixelMap）。
- `ui/library/LibraryPage.ets` —
  HomeContent 尾部 `HomePlannerSection`（`ui_planners__planners`
  节头 + `cover_0.webp` 预览卡 + 计划本标题，点按置 d2d 默认并开
  sheet）；`PlannerConfigSheet`（返回钮 + 标题 + 周起点分段 +
  2×2 封面格 + 全宽 "Create" CTA；`plannerCreating` 时替换为 fel
  模态进度视图）；`createPlannerNote`（rawfile 字节 →
  `importBundledPdfFromBytes` → `setNoteCoverPreset` → 刷新 →
  `router.pushUrl` 打开）。
- `data/NoteImporter.ets` — `importBundledPdfFromBytes`（公共薄封装 →
  `importPdfFromBytes`，原版 a2d/b13 同样复用通用管线）。
- 字符串 en+zh：`planners_title`/`planner_academic_2026_2027`/
  `planner_week_start_{monday,sunday}`/`planner_cover_*`/
  `planner_create`/`creating_planner_note`/`planner_failed`。

## 映射说明

- 原版把计划本封面作为"封面元素"挂到物化笔记上（w95 谓词筛候选
  池）；Harmony 复用 Phase 1405 的 `cover_preset` 列，键
  `planner_<index>` 与 iw2 预设键同槽——库卡片缩略图与"封面已设"
  语义自然继承。
- 原版配置屏嵌入模板 sheet 内部（x2n 双模态）；Harmony 宿主差异：
  分区入口在 Home（getting-started 等价面），配置走独立
  `bindSheet`——交互链路"列表 → 配置 → 创建 → 打开"不变。
- 原版 fel 为 Compose 模态进度卡（禁返回+吞点击）；Harmony 以
  sheet 内进度视图等价（`plannerCreating` 时整屏 LoadingProgress +
  文案，sheet 本身不可下滑关闭语义由 LARGE 态 + 无操作项承担）。
- onboarding 横幅（`academic_planner_onboarding_*`）为原版的
  首页营销卡，属一次性推广面——本 Phase 不引入，登记差异。

## Replay

`docs/migration/replays/d02-original-planner.mjs` — 86 项静态断言：
资产落库/非空、e2d/y1d 枚举序、默认 MONDAY、w95 等价键写、
fel/kan 文案、sheet 双模态组件、en/zh 字符串齐全。
