# ADR-1341：笔记封面预设（cover_preset 列 + 预设选择器）

- 日期：2026-09-21
- 状态：Accepted（preset 面实现；自定义上传面 fail-closed）
- 关联：Phase 1405；续 ADR-1337~1340（捆绑模板/集合）

## 背景

原版 1.4.2 的笔记封面是 doc 层元素：`qab.b()`（jwf 键）+ `qab.i`
中的 `ex5` 元素媒体承载封面 PDF；`d7b.b` 在 preset 选定时把
`covers/<F>.pdf`（10 个捆绑资产，`iw2`）经 SHA-512 导入 CAS 并替换
封面元素媒体；库卡片渲染封面而非页缩略图。

Harmony 笔记模型没有 doc 层封面元素——库卡片缩略图直接由第一页内容
渲染。

## 决策

1. **持久化**：`note_meta.cover_preset TEXT`（DB v76）存 preset 键
   （`iw2.F`），NULL = 无封面。放弃 CAS 资产导入——preset 资产固定于
   rawfile，键足以解析渲染源；rowToNote/buildNote/noteBucket +
   FolderRepositoryImpl 投影同步。
2. **渲染**：`LibraryPage.refreshThumbnailGeneration` 建
   `coverByNoteId`；命中 → `loadNoteCoverThumb`（PDFKit 光栅
   rawfile covers/<key>.pdf 首页）替代 `renderThumbnail`；
   `|cover:<key>` 并入 thumbnailRevision 使封面变更击穿缓存；
   未知/空键 fail-closed 回退页缩略图。
3. **选择器**：`NoteCoverSheet` = ebn.b 形态——预览卡（封面光栅 +
   noteTitle + noteDateText）、Presets 栅格（iw2.K 序 + 选中 accent
   描边）、Cancel/Done（Done 需有候选）。候选种子 = cover_preset 键
   反查（原版以 jwf→ew2 种子；preset 面语义等价）。
4. **入口**：PageOverviewPanel 页菜单 "Add Note Cover"
   （fab_templates 图标 ≈ ui_designsystem__templates），行序 = 原版
   （clear_page 之前）；作用于整本笔记，不走 runPageOperation。
5. **bump updated_at**：封面变更按 doc 变更 bump（原版即 op）。

## 差异与 fail-closed

- `ew2` 自定义上传（相册选图 → jwf 资产）：系统相册导入 + CAS 链路
  成本大，本阶段 fail-closed——preset 面自足。
- `m7b.Library`/`Templates` 入口未接（Harmony 仅 PageManager 页菜单）；
  `feature_library__add_note_cover` 在 decompile 中无调用点。
- 原版 `z5 && z4` 门控在 decompile 中不可完全解析；Harmony 面板菜单
  恒显该行（与 clear_page 同现语义一致）。
- 封面不进入文档页序列/导出——Harmony 的 cover_preset 是库投影字段，
  不写入 page 内容（原版封面元素同样不出现在页列表）。

## 后果

- preset 封面端到端可用；covers/ 10 PDF（416KB）落库。
- `d02-original-note-cover-presets.mjs` 68 checks 锁定契约。
