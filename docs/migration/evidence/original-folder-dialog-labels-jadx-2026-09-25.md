# Evidence: 原版文件夹对话框标签与选中行 a11y（JADX）

- 日期：2026-09-25
- Phase：718（ADR-0666）
- 证据来源：`decompiled_1.0.3`（只读）

## enter_folder_name（标题/字段标签择一）

`gaj.java` 文件夹对话框两处同模式：

```java
if (z8) { i5 = R.string.ui_folder__new_folder; }
else    { i5 = R.string.ui_folder__enter_folder_name; }
String strU2 = tl7.U(uz4Var3, i5);   // :630
// …同模式第二处（strU3，:719）
```

- `z8` = 创建分支：标题 "New Folder"（`ui_folder__new_folder`）。
- 重命名/编辑分支：标题与名称字段标签均为 "Enter folder name"
  （`ui_folder__enter_folder_name`）。

## ui_folder__selected（选中行 a11y）

```java
// b41.java:94 / o94.java:171 —— 选中分支内
go5.b(ue4.s(uz4Var), tl7.U(uz4Var, R.string.ui_folder__selected),
      null, ev1.b(uz4Var).d.a, uz4Var, 8, 4);
```

选中态渲染一个带 contentDescription="Selected" 的指示节点（对位
Harmony 的 ✓ 指示）。

## ui_folder__ 全族 24 键覆盖表

| 键 | 状态 |
|---|---|
| cd_confirm / cd_folder_name | 已有（文件夹表单 Save/Name 资源） |
| collapse_folder / expand_folder | 已有 `collapse_folder`/`expand_folder` |
| create_a_new_folder / new_folder | 已有 `create_folder`/`new_folder` |
| decoration_color / decoration_emoji | ADR-0505 装饰页签 |
| delete_folder_button / message + 8 矩阵键 + dialog_confirm/cancel | Phase 717（ADR-0665） |
| enter_folder_name / selected | 本阶段 |
| name_error_message | 已有 `folder_name_error` |
| unfiled | 已有 `unfiled` |

## Harmony 移植点

- `showRenameFolderDialog`：标题 `rename` → `enter_folder_name`。
- `NameDialog.placeholder` prop（默认 `name`），文件夹对话框传
  `enter_folder_name`。
- 选中行 `Text('✓').accessibilityText(folder_selected)`；
  行本身仍 `accessibilityText(item.folder.name)`。

## Replay

`d02-original-folder-dialog-labels.mjs`（12 pins）。
