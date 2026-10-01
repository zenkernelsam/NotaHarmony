# Phase 1418：最近删除页选择制界面移植报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 52 项本 Phase 检查；`note@default` /
  clean `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1418-recently-deleted-selection.md`
- 决策：`docs/migration/adr/ADR-1354-recently-deleted-selection.md`
- Replay：`docs/migration/replays/d02-original-recently-deleted-selection.mjs`

## 目标

修正 `RecentlyDeletedPage` 的移植缺陷：原版是**选择制**界面
（复选框行 + 全选行 + 已选计数横幅 + 底部批量动作条 + 复数确认
对话框），Harmony 此前误植为逐行 Recover/Delete 按钮，且与已
移植的引导文案（"Select notes to add them back into your
library…"）自相矛盾。

## 原版证据链

| 层 | 原版类 | 语义 |
|----|--------|------|
| 模型 | `p6e.invokeSuspend`→`a6e` | `.a`=Select all/Deselect all（`zx7.r(set,map.keySet())`）；`.b`=notes_selected 复数横幅（空选集为 null）；`.c`=`z5e` 行表；`.d`=选集非空使能；`.e`=delete_confirmation_message 复数；`.g`=列表空 |
| 顶部 | `wrl.i` | `o9n.a` 文本钮（Select all → `w5e(5)`=`j6e`）+ `x7n.e` 计数横幅 |
| 行 | `th3`→`wrl.h`/`x8n.a` | `fq9.p` 整行点击 = `oe(24)`→`g6e(bpj)` 切换；`mo2(7)`=`f9n.b` 复选框，cd = `cd_select/deselect_note_titled` 插值**笔记标题** |
| 底部条 | `v5e` case0 | `o9n.a`×2：Delete（`delete_notes`+`mma.G` 危险色）左、Recover notes（`recover_notes` primary）右，均 `a6e.d` 门控 |
| 确认 | `wrl.b`→`l8n.c` | 无标题；正文 = 复数 "Permanently delete N note(s)?\nThis action cannot be undone."；[Keep notes] 关闭 / [Delete] 确认（`iqm` 调用点证 str 槽为钮文案） |
| 动作 | `w5e`→`q6e` | case0/1=dismiss/confirm；case2/3=Delete/Recover 请求；case5=`j6e` 全选切换 |

## Harmony 实现（`RecentlyDeletedPage.ets`）

1. `@State selectedTrashIds: string[]`；`reloadPage` 后按现存 id
   剪除失效选中。
2. 顶部：Select all / Deselect all 文本行（复用 `select_all`，
   新增 `feature_settings__deselect_all`）→ `toggleSelectAll`；
   选集非空时显示 `notes_selected_one/other` 复数横幅。
3. 行：标题 + `recently_deleted_meta` 副文 + 尾随 `Checkbox`
   （`.select` + `cd_select/deselect_note_titled` 插值
   `noteDisplayTitle` 物化标题）；整行 `onClick` →
   `toggleNoteSelection`；复选框 `hitTestBehavior(None)` 只做
   语义呈现，触摸统一走行点击，杜绝双重切换。
4. 底部固定动作条（列表非空）：Delete（danger）+ Recover notes，
   `enabled = 选集非空 && !busy`。
5. `confirmDeleteSelected`：`showAlertDialog` 无标题，正文 =
   `delete_confirmation_message_one/other` 复数插值数量，
   Keep notes 关闭 / Delete（danger）→ `permanentlyDeleteSelected`
   （逐 id `repo.deleteNote`）；`recoverSelected` 逐 id
   `repo.restoreNote`。
6. 新增字串 en+zh：`feature_settings__deselect_all` /
   `notes_selected_{one,other}` / `delete_confirmation_message_
   {one,other}` / `recover_notes` / `delete_notes` / `keep_notes`；
   复用 `select_all`（值与原版逐字一致）与既有
   `cd_select/deselect_note_titled`。

## Fail-closed（记录不迁移）

- **note_limit_recover_\*** 上限挽留（`wrl.f`/`l8n.e`/`a6e.f`）：
  付费墙流程，Harmony 无笔记上限模型。
- **工具箱三串**（本 Phase 调研判定，证据 §7）：`cd_hide_tools`
  （`wpb`/`hx7` 主副双条工具箱无宿主）、`cd_audio_player_settings`
  （`kom` 行内播放器无宿主）、`cd_playback_position`（`tfl` 行内
  滑杆无宿主）。

## 适配说明

- `cd_delete_recording`：原版插值录音显示名（`kd6`）；Harmony
  "Delete Recording %d" 与行标题 "Recording %d" 展开后播报等价
  ——资源形差异，语义等价，记为适配。
- 复数键拆 `_one`/`_other`（SDK 仅异步 `getPluralString`，沿用
  `delete_note_title_one` 既有约定）。

## 验证

- 本 Phase Replay：52/52 通过。
- 邻接回归：`d02-original-note-soft-delete-parity`（永久删除调用
  点锚改 `(noteId|id)` 正则）81/81；`d02-original-library-
  title-fallback` 36/36；`d02-original-nav-action-glyphs` 46/46。
- 全量 Desktop Replay：1270/1270。
- `note@default` / clean `note@ohosTest` 构建通过。

## 遗留

- `deselect_all` 旧键（"Deselect All"）保留供库多选界面使用；
  本页使用逐字原名的 `feature_settings__deselect_all`。
- 行内前导图标位（`y8(str2)`/`z5e.d`）未移植：原版该行携
  `ycb.l()`/`ycb.k()` 图标名+色调，属笔记类型缩略指示，Harmony
  无对应注册表，保留为有意差异。
