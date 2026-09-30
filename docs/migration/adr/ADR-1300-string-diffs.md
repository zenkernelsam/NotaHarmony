# ADR-1300：字符串大小写/措辞修正（第二批）

## 状态

已接受（Phase 1359）。

## 决策

修正 6 处 base 串为原版逐字节：`new_note`→"New Note"、
`add_page`→"Add page"、`more_page_actions`→"More
actions"、`copy_note_id`→"Copy note ID"、`pages_deselect_
all`→"Deselect All"、`show_in_folder`→"Show in folder"。

## 理由

系统化比对 `strings.xml`：这些为真实大小写/措辞差异
（原版句首式/标题式不一致，Harmony 此前自拟）。
`app_name`="Nota"、`empty_shared_notes` 缺失、跳转对话
框更明确文案判定为合理保留（移植命名/fail-closed 特性/
清晰度改进）。

## 后果

UI 措辞逐字节对齐推进 —— 真实差异修正。
