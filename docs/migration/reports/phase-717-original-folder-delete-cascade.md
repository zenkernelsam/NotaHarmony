# Phase 717：原版文件夹删除级联语义 + kcj 计数矩阵对话框

`ui_folder__*` 族审计发现**语义级分歧**：原版删除文件夹级联删除子
文件夹与子树笔记（对话框明确承诺 "will also delete"），而 Harmony
移植按 ADR-0158 保留笔记（移入未归档）。本阶段按原版证据改级联，
ADR-0158 被 ADR-0665 取代。

## 原版证据

- `kcj.java`：`kcj.a(title, i, i2, confirm, cancel)` 九格分支——
  `i`=后代文件夹数、`i2`=子树笔记数；0,0 时 `strT=null` 无 detail 行；
  其余八格引用 `ui_folder__delete_folder_{single|plural}_{folder|note}…`
  共 8 条 "Deleting \"%1$s\" will also delete …" 文案。
- `gsi.java:936`：`kcj.a(title, fq4Var.k(), fq4Var.h().size(), …)`；
  `vad.java:143` 构造 `dq4`：`k()` = 直属子列表 size + Σ 后代 `k()`
  （递归后代文件夹数），`h()` = 直属 + 全部后代笔记 id 去重集。
- 标题 `ui_folder__delete_folder_message`="Delete folder?"，
  按钮走设计系统 `confirm`/`cancel`（"Confirm"/"Cancel"）。
- 计数语义：i 不含根（"also delete" 指后代），i2 含全子树笔记。

## 实现

- `FolderRepositoryImpl.deleteFolder`（同事务）：子树笔记
  `folder_id=NULL` + `deleted_at=now`——软删进 Recently Deleted
  （可恢复，非永久删），随后删 folder 行（子文件夹 `ON DELETE
  CASCADE` 不变）。`movedNoteIds` 字段名保留（注释标注实为回收站集）。
- `LibraryViewModel.publishCommittedFolderDelete`：`moved` 集笔记
  直接剔除（原 `noteWithFolder(note,null)` 改 `continue`）；根列表
  `committedNotes` 路径补 `deletedAt === null` 过滤，无残留卡片。
- `LibraryPage.confirmDeleteFolder`：`isFolderInSubtree` 求全子树
  （含根）→ `childFolders = len-1`；`getAllNotes()`（已排回收站）
  统计子树内笔记 → `folderDeleteDetail()` 选九格文案 → 对话框
  标题 `delete_folder_message` + detail `message`。
- 新增 `folder_delete_detail_{empty,1f,nf,1n,nn,1f_1n,1f_nn,nf_1n,
  nf_nn}` 双 locale ×9；`delete_folder_message` 改为 "Delete folder?"/
  "删除文件夹？"（原值带错误承诺已废弃）。
- 偏差记录：按钮保留 Harmony 破坏性 `Delete`（原版为设计系统通用
  "Confirm"）；0,0 情形 ArkUI 必填 message → 显示文件夹名 `%s`。

## 验证

- 新增 `d02-original-folder-delete-cascade.mjs`（43 断言：kcj 八键/
  0,0 分支/`gsi` 入参/`vad` 构造、仓库软删字段、ViewModel 剔除、
  九格 helper/后代计数、双 locale 文案）。
- `d02-folder-subtree-delete-preserves-notes.mjs` 更新为软删时序断言
  （事务顺序不变，6/6 绿）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
