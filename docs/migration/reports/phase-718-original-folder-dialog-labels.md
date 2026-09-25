# Phase 718：原版文件夹对话框标签 + 选中行 a11y 收尾

`ui_folder__*` 族收尾（24 键）：Phase 717 覆盖删除矩阵后，余下
`enter_folder_name`/`selected` 两处可移植小缺口。

## 原版证据

- `gaj.java:630`/`719`：`z8 ? new_folder : enter_folder_name`——
  创建态标题 "New Folder"，重命名态标题与名称字段标签均为
  "Enter folder name"（Harmony 重命名错用通用 `rename` 标题 +
  "Name" 占位）。
- `b41.java:94`/`o94.java:171`：选中分支渲染带
  contentDescription="Selected"（`ui_folder__selected`）的指示
  节点——对位 Harmony 的 `✓` 选中指示。
- 其余键（collapse/expand、create_a_new_folder、decoration_*、
  name_error_message、unfiled 等）均已覆盖（见 evidence 覆盖表）。

## 实现

- `showRenameFolderDialog`：标题 `rename` → `enter_folder_name`。
- `NameDialog` 新增 `placeholder` prop（默认 `name`，笔记重命名
  不变），文件夹对话框传 `enter_folder_name`。
- 选中行 `Text('✓')` 挂 `accessibilityText(folder_selected)`；
  行级仍朗读文件夹名。
- 新串 `enter_folder_name`（"Enter folder name"/"输入文件夹名称"）、
  `folder_selected`（"Selected"/"已选中"）。

## 验证

- `d02-original-folder-dialog-labels.mjs`（12 断言：gaj 择一证据、
  b41/o94 语义引用、标题/占位接入、✓ a11y、双 locale）。
- `ui_folder__*` 族至此全量审计完毕（ADR-0665 + ADR-0666 + 已有覆盖）。
- 全套件重跑、双 HAP 构建通过后记录于修复总纲。
