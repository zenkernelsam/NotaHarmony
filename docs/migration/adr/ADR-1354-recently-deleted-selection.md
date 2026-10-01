# ADR-1354 最近删除页选择制界面（全选行 / 复选框行 / 批量条）

- 状态：Accepted
- 日期：2026-10-01
- 关联 Phase：1418
- 接续：ADR-1353（设置页 About 区）；同族 fail-closed：ADR-0641/ADR-0652
- 证据：`docs/migration/evidence/phase-1418-recently-deleted-selection.md`

## 背景

原版 Recently Deleted（`p6e`/`a6e` VM + `wrl`/`v5e`/`th3`/`mo2`
渲染族 + `w5e`→`q6e` UserAction）是**选择制**界面：顶部
Select all/Deselect all 行 + "N notes selected" 横幅，行 =
整行点击切换的复选框行，底部 Delete/Recover notes 批量条以
选集非空门控。Harmony `RecentlyDeletedPage` 此前是逐行
Recover/Delete 双按钮——既偏离原版交互，也与已移植的空态文案
（"Select notes to add them back…"）自相矛盾。

## 决策

### 移植

1. **选择态**：`@State selectedTrashIds: string[]`；`reloadPage`
   重建列表后剪除失效 id（原版选集与列表同一状态流）。
2. **顶部区**（`wrl.i` 对齐）：Select all / Deselect all 文本行
   （`zx7.r` 全选判定 → `j6e` 切换）+ 选集非空时
   `feature_settings__notes_selected` 复数横幅。
3. **行**（`wrl.h`/`x8n.a` 对齐）：标题 + "Deleted %s" 副文 +
   尾随 `Checkbox`；整行 `onClick` 切换（`fq9.p`/`g6e` 等价）；
   复选框 `hitTestBehavior(None)` 只做语义+视觉呈现，避免
   点击被行与框各消费一次造成双切换。复选框 a11y =
   `cd_select_note_titled`/`cd_deselect_note_titled` 插值
   **物化标题**（空标题落 `untitled_note`，同 `z5e` 标题规则）。
4. **底部批量条**（`v5e` case0/`x7n.e(!a6e.g)`）：列表非空时
   固定显示，Delete（danger）左、Recover notes 右，均
   `enabled = 选集非空 && !busy`（`a6e.d`）。
5. **删除确认**（`wrl.b`/`l8n.c`）：无标题，正文 =
   `delete_confirmation_message` 复数（"Permanently delete N
   note(s)?\nThis action cannot be undone."），主钮 Keep notes
   关闭，次钮 Delete（danger）确认。
6. 移除逐行 Recover/Delete 按钮——原版行内无此物。

### Fail-closed

- **note_limit_recover_\***（`wrl.f`/`l8n.e`/`a6e.f`）：恢复超免费
  上限的付费挽留对话框，Harmony 无笔记上限模型，fail-closed。
- **工具箱同批三串**（本 phase 调研一并判定，详见证据 §7）：
  `cd_hide_tools`（双条工具箱 `wpb`/`hx7` 无宿主）、
  `cd_audio_player_settings`（`kom` 行内播放器无宿主）、
  `cd_playback_position`（`tfl` 行内滑杆无宿主）——全部
  fail-closed，不伪造不存在的控件。

### 有意差异

- `cd_delete_recording` 资源形 `Delete %1$s`(名字) → Harmony
  `Delete Recording %d`：播报文本等价，记为适配不返工。
- 复数拆 `_one`/`_other` 双键（SDK 仅异步 getPluralString）；
  `select_all` 复用（值与 `feature_settings__select_all`
  逐字一致）。

## Replay

- `docs/migration/replays/d02-original-recently-deleted-selection.mjs`：
  52 项覆盖 `p6e` 模型、`wrl.*`/`v5e`/`mo2`/`th3`/`w5e` 动作链、
  原版资源、Harmony 实现与 fail-closed 钉。
- `d02-original-note-soft-delete-parity.mjs`：永久删除调用点改
  正则锚 `(noteId|id)`（批量循环变量名变化）。
