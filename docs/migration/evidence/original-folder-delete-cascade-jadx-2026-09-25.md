# Evidence: 原版文件夹删除级联 + kcj 计数矩阵（JADX）

- 日期：2026-09-25
- Phase：717（ADR-0665，取代 ADR-0158）
- 证据来源：`decompiled_1.0.3`（只读）

## 原版调用链

```
gsi.java:936      kcj.a(title, iK, size, confirm, cancel, ...)
                    iK  = fq4Var.k()          —— 后代文件夹总数
                    size= fq4Var.h().size()   —— 子树笔记数
vad.java:143      new dq4(..., g=arrayList2 /*子文件夹*/,
                           h=arrayList3.size() /*本文件夹直属笔记*/,
                           i=iK /*size + Σ children.k() 递归后代数*/,
                           j=X1(arrayListA1) /*直属+后代笔记 id 去重集*/)
kcj.java          九格分支矩阵（见下）
```

## kcj 九格矩阵（`kcj.a` 内 `i`/`i2` 分支）

| i（后代文件夹） | i2（子树笔记） | 资源 | 原文 |
|---|---|---|---|
| 0 | 0 | —（`strT = null`，无 detail 行） | — |
| 1 | 0 | `single_folder` | `Deleting "%1$s" will also delete 1 folder.` |
| >1 | 0 | `plural_folders` | `Deleting "%1$s" will also delete %2$d folders.` |
| 0 | 1 | `single_note` | `Deleting "%1$s" will also delete 1 note.` |
| 0 | >1 | `plural_notes` | `Deleting "%1$s" will also delete %2$d notes.` |
| 1 | 1 | `single_folder_single_note` | `Deleting "%1$s" will also delete 1 folder and 1 note.` |
| 1 | >1 | `single_folder_plural_notes` | `Deleting "%1$s" will also delete 1 folder and %2$d notes.` |
| >1 | 1 | `plural_folder_single_note` | `Deleting "%1$s" will also delete %2$d folders and 1 note.` |
| >1 | >1 | `plural_folders_plural_notes` | `Deleting "%1$s" will also delete %2$d folders and %3$d notes.` |

对话框标题 `ui_folder__delete_folder_message` = "Delete folder?"，
按钮 `ui_folder__dialog_confirm` → `ui_designsystem__confirm`（"Confirm"）、
`ui_folder__dialog_cancel` → `ui_designsystem__cancel`（"Cancel"）。

## 语义结论

1. 所有非空文案均为 **"will also delete"**：原版承诺级联删除子文件夹
   与子树内笔记，而非移动笔记。
2. `i` 是**后代文件夹数（不含根）**——`iK` 初值为直属子列表 `size`，
   再累加每个后代的 `k()`；对话框对根文件夹自身的删除由标题承载。
3. `i2` 是**子树全量笔记**（`h()` = 直属 + 全部后代的笔记 id 集去重）。

## Harmony 移植点

| 原版 | Harmony |
|---|---|
| `fq4.k()` 后代文件夹数 | `isFolderInSubtree` 全子树 − 根（`subtreeIds.length - 1`） |
| `fq4.h().size()` 子树笔记 | `getAllNotes()`（已排除回收站）∩ 子树 folderId |
| 九格矩阵 | `LibraryPage.folderDeleteDetail()` + `folder_delete_detail_*` ×9 |
| 级联删除 | `deleteFolder` 同事务置 `folder_id=NULL` + `deleted_at=now`（软删进 Recently Deleted，可恢复） |
| Confirm/Cancel | Cancel + Delete（红色破坏性按钮；原文 Confirm 为设计系统通用词，Delete 语义更明确——记录偏差） |
| 0,0 → 无 detail | ArkUI AlertDialog 需要 message → 显示 `%s`（文件夹名） |

## Replay

`docs/migration/replays/d02-original-folder-delete-cascade.mjs`（43 pins）；
旧 `d02-folder-subtree-delete-preserves-notes.mjs` 更新为软删时序断言。
