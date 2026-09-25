# ADR-0687：原版空标题兜底与回收站副标题对齐

- 状态：已接受
- 日期：2026-09-25
- 关联：`docs/migration/evidence/original-library-title-fallback-jadx-2026-09-25.md`、
  `docs/migration/replays/d02-original-library-title-fallback.mjs`、
  `docs/migration/reports/phase-739-original-library-title-fallback.md`

## 背景

两个同族渲染缺口：

1. **库卡片空标题渲染空白**：原版 `e5j.h` 在 `w09.d`（物化标题）为
   null 时替换为 `data_library_state__default_note_title`（"New Note"），
   `b5j/cti/m5j` 三种卡面共用；`y5j.java:59` 进一步证明原版对
   `null || length()==0` 一并兜底。Harmony `note.title` 列
   `NOT NULL DEFAULT ''`，`renameNote('')` 物化为 `''`，卡片
   `Text(note.title)` 直接渲染空白 —— 与原版 "New Note" 不一致。
2. **回收站行副标题格式/内容双偏**：原版 `bib`/`nhb` 行副标题 =
   `feature_settings__note_deleted_at`（"Deleted %1$s"）+
   `z5c.n` 中号本地化日期，无剩余天数段；Harmony 原渲染
   `YYYY-MM-DD` ISO 日期并自加 `· %d days left`（原版资源中无
   days-left 文案）。

## 决策

1. 库卡片两处 `Text(note.title)` 应用 `e5j.h` 等价判定
   `note.title.length > 0 ? note.title : $r('app.string.untitled_note')`
   —— 与 `ImportDetailsSheet`、`RecentlyDeletedPage` 既有约定一致；
   Harmony `''` 即原版 null 的规范化形式（ADR/注释已记）。
2. `RecentlyDeletedPage.formatDeletedTime` 改
   `Intl.DateTimeFormat(undefined, { dateStyle: 'medium' })`
   （`z5c.n` 等价物，try/catch 兜底同 Phase 738）。
3. `recently_deleted_meta` 值改 `"Deleted %s"` / `"删除于 %s"`（保留
   键名以兼容既有 fixture），移除 Harmony 自加的 `· %d days left`
   段；删除 `daysLeft`/`MS_PER_DAY` 死代码与 `TRASH_RETENTION_MS`
   页面级引用（仓库内 `purgeExpiredTrash` 仍使用，不受影响）。
4. 回收站行标题空题兜底（`untitled_note`）已在，符合 `bib` 的
   `strL != null ? title : default` 语义，不动。

## 影响

- `note/src/main/ets/ui/library/LibraryPage.ets`：两处卡片标题兜底。
- `note/src/main/ets/noteformability/pages/{FolderNotesCard,
  RecentNotesCard,NoteThumbnailEditPage}.ets`：组件卡同法兜底
  （原版 `nti`/`ksh` 订阅源同规则）。
- `note/src/main/ets/ui/settings/RecentlyDeletedPage.ets`：副标题
  本地化中号日期 + 移除 days-left 段。
- `note/src/main/resources/base/element/string.json`、
  `zh_CN/element/string.json`：`recently_deleted_meta` 值收窄为单参。
- 可见差异：空标题卡片显示 "New Note"/"新笔记"；回收站副标题
  "Deleted Jan 5, 2026"/"删除于 2026年1月5日"。
