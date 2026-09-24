# ADR-0635 — 原版 FolderNotesWidgetProvider → folder_notes_card 配置型数据卡片

日期：2026-09-24
状态：已实施（含 3 项文档化适配；NoteThumbnail 继续 fail-closed）

## 决策

以 `folder_notes_card` ArkTS 卡片 + `FolderNotesFormFeed`（formId→
folderId 绑定存 filesDir JSON）+ `FolderFormEditAbility`（type=
formEdit）+ `FolderNotesEditPage`（文件夹选择）复刻原版
FolderNotesWidgetProvider + FolderNotesConfigActivity：头部→
VIEW+folder_id 落地、创建钮→CREATE_NOTE+folder_id 建进该文件夹、
行→note_id、缩略图/占位/分隔线/空态/未配置态齐备。

## 证据锚点

`FolderNotesWidgetProvider.java`（extends qk9；g() 用 wyi.c 取绑定
folderId → xld(title/CREATE_NOTE+folder_id/VIEW+folder_id/笔记集)）、
`wyi.java`（widget_bindings SharedPreferences "folder_"+id）、
`FolderNotesConfigActivity.java`、`strings.xml`（folder_no_notes /
folder_empty）。详见
`docs/migration/evidence/phase-668-original-folder-notes-card.md`。

## 连带实现的原版 extras

- `folder_id`（VIEW）→ OpenTargetIngress → `landInFolder`（先校验
  存在 → `vm.setFolder`；缺失即不动 = 原版 g() null 语义）。
- `folder_id`（CREATE_NOTE）→ LaunchActionIngress `LaunchRequest`
  → `createAndLaunch(folderId)` → `vm.createNote(folderIdOverride)`
  —— 新笔记建进指定文件夹而不切当前库位置。

## 文档化适配（非 fail-closed，行为等价）

1. **配置时机**：原版添加部件时强制配置活动；Harmony formEdit 为
   后置编辑（卡片内 ✎/未配置态点按 → onFormEvent →
   openFormEditAbility）。未配置态沿用原串 "Tap to open
   Notability" 作引导。
2. **绑定存取**：widget_bindings SharedPreferences →
   `filesDir/folder_notes_form_config.json`（formId→folderId，
   UIAbility/FormExtension/formEdit 同沙箱可读写）。
3. **刷新触发**：同 ADR-0634 —— loadNotes 完成点推送 + 扩展侧
   标题先行/缩略图 UIAbility 侧补齐；缩略图跨卡片实例按 noteId
   去重渲染（pushNoteListForms 共享引擎）。

## fail-closed 保留

- `NoteThumbnailWidgetProvider`（wyi.e "note_"+id 单缩略图配置型
  部件）：剩最后一张未实现，登记为独立后续阶段。

## 验收

- Replay：`d05-original-folder-notes-card.mjs` 30/30 绿；P665/P667
  fixtures 的计数与 fail-closed pin 同步更新。
- 全量 Desktop Replay、clean + note@ohosTest + note@default 双 HAP
  构建全绿。
