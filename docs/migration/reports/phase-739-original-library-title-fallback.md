# Phase 739 — 原版空标题兜底 + 回收站副标题对齐

- 日期：2026-09-25
- 类型：真实语义缺口修复（渲染兜底 + 副标题格式）
- ADR：ADR-0687
- 证据：`docs/migration/evidence/original-library-title-fallback-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-library-title-fallback.mjs`

## 背景

追查 `w09.e`（Phase 738 副标题）时顺带钉死同卡片模型的 `w09.d`
标题渲染路径与回收站行构建器，发现两个同族缺口。

## 原版证据

- `e5j.h(str)`：`str == null` → `data_library_state__default_note_title`
  （"New Note"）；`b5j/cti/m5j` 三种卡面共用该兜底。`y5j.java:59`
  显式 `null || length()==0` 兜底，证明空串同样走默认题。
- `bib.java:43`/`nhb`：回收站行标题 null→默认题；副标题 =
  `feature_settings__note_deleted_at`（"Deleted %1$s"）+ `z5c.n`
  中号本地化日期，原版无 days-left 文案。

## Harmony 缺口与修复

| 缺口 | 原版 | 修复前 | 修复后 |
|------|------|--------|--------|
| 库卡片空标题 | "New Note" | `Text(note.title)` 渲染空白 | `untitled_note` 兜底 |
| 回收站副标题 | "Deleted Jan 5, 2026" | "Deleted 2026-01-05 · N days left" | "Deleted %s" + Intl medium 日期 |

`note.title` 为 `NOT NULL DEFAULT ''`，`renameNote('')` 物化 `''`
= 原版 null 的规范化形式，渲染判定 `length > 0` 与 `e5j.h`/`y5j`
等价；与 `ImportDetailsSheet`/`RecentlyDeletedPage` 既有约定一致。

移除死代码：`daysLeft`、`MS_PER_DAY`、页面级 `TRASH_RETENTION_MS`
引用（仓库内 `purgeExpiredTrash` 仍用）。

## 变更

- `note/src/main/ets/ui/library/LibraryPage.ets`（2 处卡片标题）
- `note/src/main/ets/noteformability/pages/FolderNotesCard.ets`、
  `RecentNotesCard.ets`、`NoteThumbnailEditPage.ets`（组件卡兜底）
- `note/src/main/ets/ui/settings/RecentlyDeletedPage.ets`
- `note/src/main/resources/base/element/string.json`、`zh_CN`（
  `recently_deleted_meta` 收窄为单参）

## 验证

- 聚焦 Replay `d02-original-library-title-fallback`：36 断言全绿。
- 全量 Desktop Replay：8963/8963 全绿。
- ArkTS 构建 `note@default` 通过；clean + `note@ohosTest` +
  `note@default` 双 HAP 成功（仅存量告警）。

组件卡三处（`FolderNotesCard`/`RecentNotesCard`/
`NoteThumbnailEditPage`）同步兜底 —— 原版组件订阅源 `nti`/`ksh`
同样应用 `default_note_title`（证据 8-9）。

## 遗留

- 模拟器/真机/Hypium 未执行（按规则）。
