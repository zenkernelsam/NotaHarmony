# ADR-0513 — 原版笔记上下文菜单补齐

状态：Accepted（Phase 541）

## 背景

Phase 537 落地了菜单中的 Favorite/Unfavorite 与 Delete 末位；原版
`d5j` 菜单完整序为 Rename → Favorite → Duplicate → Export →
Export options → Open in new window → Show in folder → Sort to
folder → Copy note ID → Report → Delete。Harmony 缺 Rename、
Duplicate、Export、Show in folder、Copy note ID 五项可移植项。

## 决策

1. 菜单按原版可移植子集顺序补齐：Rename → Favorite → Duplicate →
   Export → Show in folder → Move to folder（≡sort_to_folder）→
   Copy note ID → Delete。
2. Rename：`NameDialog` 增 `showDecoration` 门（文件夹=true，
   笔记=false）；仓储接口新增 `renameNote` → `updateNoteTitle`
   （原版 SET_TITLE op + history 支持）。
3. Duplicate：复用 `exportNote`→`importFromData` 无损包往返；
   导入器在源 id 存在时分配新 id。op 史不复制——登记。
4. Export：既有 `exportToFile` 单笔记落盘 + toast。
5. Show in folder：`setFolder(note.folderId)` 导航；未归档笔记置灰
   （原版该项对无文件夹者无意义——登记）。
6. Copy note ID：pasteboard 明文 + toast。
7. Export options / Open in new window / Report note：分享面板、
   多窗口、反馈服务不可移植——登记。

## 验证

`d02-original-note-context-menu.mjs` 43/43；全套 436/436；
note@default + note@ohosTest BUILD SUCCESSFUL。
