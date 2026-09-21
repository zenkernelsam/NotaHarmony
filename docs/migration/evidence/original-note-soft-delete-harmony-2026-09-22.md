# Harmony 证据：原版笔记软删（Recently Deleted）模型 — 2026-09-22

## 目标

对照原版 Notability 1.0.3（decompiled_1.0.3）的笔记删除生命周期，修复 Harmony 此前
"删除即硬删"的差异（Phase 530 登记的 SCHEMA-D1），实现与原版一致的
软删 → 30 天保留 → 永久删除 + 墓碑 语义。

## 原版证据

### 写路径

- `defpackage/leb.java` — 移入回收站（p89.b 调用）：
  1. `xp1.d(noteId, rp1.K)` 读取该笔记的 UNDELETE 队列行；
  2. 若存在，先经 `l96.L0(... q0(21, ...))` 删除该 UNDELETE 行；
  3. `new sp1(noteId, rp1.J=DELETE, deletedAt=new xgb(now))` 写 DELETE 行。
  `ClientNoteUpdate` 复合主键为 `(id, type)`（`vp1.java:17`）。
- `defpackage/tp1.java` — 恢复：`DELETE FROM ClientNoteUpdate WHERE id=? AND type!='PERMANENTLY_DELETE'`，
  即删除 DELETE 队列行即完成恢复（本地不另写 UNDELETE 行；UNDELETE 行是服务端下发的合并状态）。
- `defpackage/wp1.java:544` — `INSERT INTO PermanentlyDeletedNote(noteId)` 墓碑插入；
  `defpackage/cha.java` 为其 DAO update 绑定。

### 读路径（x17.java:143 ClientPivot）

```sql
WITH ClientPivot AS (
  SELECT id,
    MAX(CASE WHEN type='EDIT' THEN createdAt END)  AS editCreatedAt,
    MAX(CASE WHEN type='EDIT' THEN favorite END)   AS editFavorite,
    MAX(CASE WHEN type='EDIT' THEN lastOpened END) AS editLastOpened,
    MAX(CASE WHEN type='EDIT' THEN folderId END)   AS editFolderId,
    MAX(CASE WHEN type='DELETE' THEN deletedAt END) AS deleteDeletedAt,
    MAX(CASE WHEN type='UNDELETE' THEN 1 END)      AS hasUndelete,
    MAX(CASE WHEN type='PERMANENTLY_DELETE' THEN 1 END) AS hasPermanentlyDelete
  FROM ClientNoteUpdate GROUP BY id),
AllNotes AS (
  SELECT id FROM (
    SELECT id FROM SyncedNoteMetadata
    UNION ALL
    SELECT id FROM ClientPivot
    WHERE id NOT IN (SELECT id FROM SyncedNoteMetadata)
      AND hasPermanentlyDelete IS NULL
      AND editCreatedAt IS NOT NULL)
  WHERE id NOT IN (SELECT noteId FROM PermanentlyDeletedNote))
SELECT ...,
  CASE WHEN cp.deleteDeletedAt IS NOT NULL THEN cp.deleteDeletedAt
       WHEN cp.hasUndelete = 1 THEN NULL
       ELSE snm.deletedAt END AS deletedAt, ...
FROM AllNotes an
LEFT JOIN SyncedNoteMetadata snm ON an.id = snm.id
LEFT JOIN ClientPivot cp ON an.id = cp.id
WHERE cp.hasPermanentlyDelete IS NULL
```

deletedAt 优先级：客户端 DELETE > 客户端 UNDELETE > synced.deletedAt。

### 用户可见行为（resources/res/values/strings.xml）

- `feature_settings__recently_deleted` = "Recently Deleted"（设置页入口）
- `feature_settings__recently_deleted_empty_state_header` =
  "Select notes to add them back into your library. Unless recovered, notes in this
  list will be permanently deleted after 30 days."
- `feature_settings__recently_deleted_empty_state_message` = "No recently deleted notes"
- `feature_settings__recover_notes` = "Recover notes"

## Harmony 适配决策

原版 `ClientNoteUpdate` 是为多设备同步设计的乐观更新队列（EDIT 行合并
createdAt/favorite/lastOpened/folderId，DELETE/UNDELETE/PERMANENTLY_DELETE 三类
墓碑变更）。Harmony 当前无同步端点，完整复刻队列表会是死管道。本阶段采用
**行为等价的最小模型**：

| 原版机制 | Harmony 等价物 |
| --- | --- |
| `ClientNoteUpdate` DELETE 行 `deletedAt` | `note_meta.deleted_at`（NULL=活跃） |
| `tp1` 恢复（删除 DELETE 队列行） | `deleted_at = NULL` 单 UPDATE |
| `PermanentlyDeletedNote` 墓碑 | `permanently_deleted_note(note_id)` 表 |
| AllNotes 排除墓碑/PD 行 | `noteIdExists` 把墓碑 id 视为占用 |
| 30 天自动清除 | `purgeExpiredTrash`（资料库/回收站页加载时结算） |
| Recently Deleted 列表 | `getTrashedNotes()`（`deleted_at IS NOT NULL ORDER BY deleted_at DESC`） |

行为差异分析：原版队列模型的全部用户可见行为（软删、恢复、永久删除防复活、
30 天清除、回收站列表）在本地等价模型下完全一致；唯一牺牲的是未来同步所需的
乐观更新历史，届时可在该列基础上演化为队列。

## Harmony 落点

| 文件 | 变更 |
| --- | --- |
| `data/DatabaseHelper.ets` | `DB_VERSION=67`；`note_meta.deleted_at`；`DDL_PERMANENTLY_DELETED_NOTE`；`MIGRATIONS[67]`（ALTER + CREATE）；`idx_note_meta_deleted_at` |
| `data/DatabaseManager.ets` | `ddlList` 注册墓碑表（每次 open 幂等创建） |
| `core/model/NoteTypes.ets` | `NoteMeta.deletedAt: number \| null` |
| `data/NoteRepositoryImpl.ets` | `getAllNotes/getNotesByFolder/searchNotes` 过滤 `deleted_at IS NULL`；新增 `getTrashedNotes/trashNote/restoreNote/purgeExpiredTrash`；`deleteNote` 写墓碑 + 清 `search_item` + `recordTombstone` 参数；`TRASH_RETENTION_MS = 30d` |
| `data/RepositoryInterfaces.ets` | 新增四个契约方法 |
| `data/NoteImporter.ets` | 回滚 `deleteNote(noteId, false)` 不写墓碑；`noteIdExists` 含墓碑 id（永不复活） |
| `ui/library/LibraryViewModel.ets` | `deleteNote` → `trashNote`；`loadNotes` 先 `purgeExpiredTrash` |
| `ui/settings/RecentlyDeletedPage.ets` | 新页面：列表、Recover、Delete Permanently（确认框）、30 天说明、空态、打开即结算 |
| `ui/settings/SettingsPage.ets` | "Recently Deleted" 入口按钮 |
| `resources/base/profile/main_pages.json` | 注册路由 |
| `resources/{base,zh_CN}/element/string.json` | 10 个新字符串；`delete_note_message` 改为回收站措辞 |

## 边界与后续

- `search_item` 清理由本阶段补入 `deleteNote`（此前永久删除会留索引孤儿行——顺带修复）。
- 软删保留 `folder_id`、`favorite`、页面/元素/资产/搜索索引行，恢复为单 UPDATE——与
  原版"DELETE 行不触碰 EDIT 字段"一致。
- 备份/导出经 `getAllNotes` 自动排除回收站笔记，符合原版库外不可见语义。
- 已知差异：原版回收站是选择式批量操作（"Select notes to add them back"），本页为逐条
  Recover/Delete；批量选择与"全部清空"列为后续增强。
- 未启动模拟器、虚拟机、真机或 Hypium；验证全部来自静态检查、Replay 与 HAP 构建。
