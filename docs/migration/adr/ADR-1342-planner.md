# ADR-1342：计划本（Academic Planner）——x1d/e2d/y1d 移植

- 日期：2026-10-01
- 状态：Accepted（实现面）；差异登记见下
- 关联：Phase 1406；续 ADR-1337~1341（捆绑模板/封面预设）

## 背景

原版 1.4.2 自带"计划本"：getting-started 面有 "Planners" 分区
（`a1n.d`/`hel.c`），点按进入嵌在模板 sheet 内的配置屏
（`x2n.c`/`hel.b`：周起点分段 + 四封面格 + Create CTA），创建时
`a2d` 把 `planners/academic_planner_2026_2027-{monday,sunday}_
start.pdf` 喂进通用 PDF→笔记导入管线，物化后封面元素 =
所选 `y1d`（`w95` 谓词筛封面候选池），进度 `fel` 模态、失败
`kan` snackbar。

Harmony 既有：Phase 1405 的 `cover_preset` 列 + 缩略图渲染管线；
`NoteImporter.importPdfFromBytes` 完整 PDF→笔记物化。

## 决策

1. **资产**：`rawfile/planners/` 存 2 PDF（周一/周日起点）+
   `cover_{0..3}.webp`（y1d 四封面，SHA-256 与原版一致）。
2. **目录**：`PlannerCatalog` 等价 `x1d`（单计划本）/`e2d`
   （weekStart 序 MONDAY→SUNDAY，`fileSegment` 即文件名段）/
   `y1d`（四封面，`presetKey='planner_<index>'`）；默认选择
   `d2d` 语义 = 首封面 + MONDAY。
3. **入口宿主**：原版挂在 getting-started 面（`w0n`/`oih`/`a1n.d`）；
   Harmony 等价面 = 库 Home（`HomeContent`）尾部 "Planners" 分区。
   原版的"模板 sheet 双模态"（`x2n.j`↔`x2n.c`）映射为库侧独立
   `bindSheet` 配置屏——交互步骤不变，宿主位置登记差异。
4. **封面持久化**：不新增列——`cover_preset` 复用，
   `planner_<index>` 键与 iw2 预设同槽；`NoteCoverCatalog` 增加
   `kind:'image'` + `PLANNER_COVER_PRESETS` + `findAnyNoteCover`
   （缩略图渲染并集）+ `loadImageCoverThumb`（ImageSource 解码
   webp）。`NoteCoverSheet` 选择器仍只列十款 iw2 预设（原版
   `ebn` 选择器同样不含计划本封面）。
5. **创建**：`importBundledPdfFromBytes` 薄封装（文件名
   `"<计划本标题>.pdf"` → `pdfImportTitle` 剥名）→ 成功后
   `setNoteCoverPreset` → `router.pushUrl` 打开；创建期间 sheet
   内模态进度视图（`plannerCreating`），失败 toast
   `planner_failed`。
6. **Fail-closed / 差异登记**：
   - onboarding 营销卡（`academic_planner_onboarding_*`）不引入。
   - 原版封面经 `w95` 谓词筛候选池后由导入管线落封面元素；
     Harmony 等价改为创建后显式 `setNoteCoverPreset`。
   - 原版配置屏在模板 sheet 内；Harmony 为库侧独立 sheet。

## 验收

- Replay：`d02-original-planner.mjs` 86 断言全绿；
  `d02-original-note-cover-presets.mjs` 一处断言随渲染路径改名
  （`findNoteCoverPreset`→`findAnyNoteCover`）更新。
- HAP：`note@default` + clean `note@ohosTest` 均通过。
