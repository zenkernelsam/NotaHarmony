# Phase 1363 中文报告 — 复制确认 Toast 措辞保真

## 修正（英文 2 处）

| 键 | 旧 | 新 |
|----|----|----|
| link_copied | Link copied | Copied Link |
| note_id_copied | Note ID copied | Copied note ID |

对齐原版 `feature_note__copied_link`="Copied Link" 的 `Copied X` 语序。
中文 `已复制链接`/`笔记 ID 已复制` 语义自然，不改。

## 逐点核对的非差异

- `new_note`="New Note"：库速拨 chip，对 `shortcut_new_note`/`default_title`="New Note" 成立，
  与 `feature_library__create_note`="Create Note"（主创建钮）不同语境，不改。
- 复制/裁剪无障碍描述键保留描述性措辞。
- `feature_note/library__*` 中 88 个"缺失"键绝大多数为已 fail-closed 的特性
  （IAP 上限、Learn、Klipy GIF、MyScript HWR、协作共享、Android 默认应用角色、多窗口），
  不属于可恢复缺陷。

## 验证

`d02-copied-toast-wording.mjs` **10/10** 绿。
