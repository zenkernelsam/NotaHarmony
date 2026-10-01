# Phase 1405 证据 — 笔记封面预设（iw2/ebn/d7b/cbn.f）

## 原版实现（decompiled_1.4.2）

### 预设目录（iw2.java）

`iw2` 枚举（`covers/<F>.pdf` + drawable 预览 + 名字 res + 类目文案），
`iw2.K` 枚举序：

| key | 名字 res 值（=类目） |
|---|---|
| orange | Simple |
| sage | Simple |
| stickers | Stickers |
| logo-pattern | Logo |
| brown | Minimalist |
| maroon | Minimalist |
| blue | Plain |
| yellow | Plain |
| purple-journal | Journal |
| blue-journal | Journal |

`rs.java` case6：逐 preset `covers/<F>.pdf` → SHA-512 预摘要。

### 选择器（ebn.java / l7b / i7b / gw2）

- `i7b` UiState：{candidate: gw2, noteTitle, noteDateText, pageThumbnail}。
- `gw2` sealed：`dw2`=NoSelection / `fw2`=Preset(iw2) / `ew2`=Custom(jwf
  上传图资产引用)。
- `ebn.b`：标题 `ui_notecovers__title` "Note cover preview" + 预览卡
  `a(8, …, 预览图, noteTitle, noteDateText)`（库卡片形态）+
  `ui_notecovers__presets` "Presets" 区 + preset 栅格 + `g8n.a` 底栏
  Cancel/Done（`c85` lambda）；Done 需有候选。
- `ebn.c(bpj, m7b, onDone, jwf?)`：`m7b` = {PageManager, Library,
  Templates} 入口来源枚举；`jwf` = 既有封面元素种子（→ ew2 预选）。

### 应用路径（d7b.java）

- `selectPreset(iw2)` → 候选 `fw2`；Done → `lw2.b.b(bpj,
  "covers/<F>.pdf")`：读 asset → SHA-512 → CAS 导入 → `yac` 资产
  （null → "Cover preset unreadable" 日志）。
- `d(qab)`：找笔记封面元素（`qab.b()`=jwf，`qab.i` 中 `ex5.a.v()`
  匹配项）→ `ex5.a.B()` 媒体 → `c8c` → 字节写回 → `cbc(jwf)` 返回。
- note 不可用（`qab==null`）→ "Cover change skipped" 日志短路。

### 入口（cbn.java）

`cbn.f` 页级菜单行 `feature_note__content_manager_add_note_cover`
"Add Note Cover"（`z5 && z4` 门控，`ui_designsystem__templates` 图标，
位于 create_template 与 clear_page 之间）→ dismiss + function7 →
l7b 封面屏幕。另有 `feature_library__add_note_cover`（库入口，
decompile 内未见调用点，m7b.Library 存在即佐证）。

## Harmony 落点

- `note/src/main/resources/rawfile/covers/*.pdf`：10 个原版 PDF 资产。
- `core/model/NoteCoverCatalog.ets`：`NOTE_COVER_PRESETS`（iw2.K 序）
  + `findNoteCoverPreset` + `loadNoteCoverThumb`（rawfile→暂存→PDFKit
  首页光栅，与 BundledPaperTemplateApply 同一 recipe）。
- `DatabaseHelper` v76：`ALTER TABLE note_meta ADD COLUMN cover_preset
  TEXT DEFAULT NULL` + base DDL 同列；preset 键持久化（iw2.F），
  NULL=自动缩略图。
- `NoteTypes`：`NoteMeta.coverPreset?: string | null`。
- `NoteRepositoryImpl.setNoteCoverPreset`：mutex + 部分 UPDATE +
  bump `updated_at`（封面属 doc 变更）；rowToNote/buildNote/noteBucket
  投影补齐；`FolderRepositoryImpl` 投影同步。
- `NoteCoverSheet.ets`：预览卡（封面光栅 + 标题 + 日期）+ Presets
  3 列栅格（PDF 光栅 + 选中 accent 描边）+ Cancel/Done。
- `PageOverviewPanel`：页菜单 "Add Note Cover" 行（fab_templates 图标 ≈
  ui_designsystem__templates），位于 clear_page 之前——原版行序。
- `NotePage`：`add_cover` 动作在 runPageOperation 之前截获（作用于整本
  笔记非页操作）→ bindSheet；Done → setNoteCoverPreset → 状态回写。
- `LibraryPage`：`coverByNoteId` 查询 → 封面 preset 渲染
  covers/<key>.pdf 首页；`|cover:<key>` 并入 revision 击穿缓存；
  未知键 fail-closed 回退页缩略图。

## 未移植（fail-closed）

- `ew2` 自定义上传封面（照片选择器 → jwf 资产）—— 需系统相册接入，
  本阶段仅 preset 面。
- `m7b.Library`/`Templates` 入口：Harmony 仅接 PageManager 入口
  （content manager 页菜单）。
- 封面元素的文档内嵌形态（Harmony 以列投影近似，见 ADR-1341）。

## 验证

- `d02-original-note-cover-presets.mjs` — 68 checks。
- `note@default` clean；`note@ohosTest` clean build 成功。
- 全量基线 1257/1257。
