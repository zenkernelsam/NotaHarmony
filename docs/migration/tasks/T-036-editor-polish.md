# T-036 编辑器打磨：标题编辑 + Undo 全覆盖

## 目标

编辑器标题可行内编辑；选区变换/文本框/形状替换全部纳入 Undo/Redo。

## 实现要求

### 1. 标题编辑

修改 `NotePage.ets` 顶部栏：
- Text 显示标题 → 点击进入编辑态（TextInput，自动聚焦）
- 失焦/回车 → updateNote 保存标题 + 刷新资料库
- 空标题显示"未命名笔记"占位

### 2. Undo 全覆盖

检查 `UndoRedoManager` 当前覆盖范围，补齐以下操作的入栈：

| 操作 | UndoableActionType | 说明 |
|------|-------------------|------|
| 选区移动/缩放/旋转 | TRANSFORM_STROKES | before/after 快照 |
| 选区删除 | ERASE_STROKES | removedStrokes |
| 文本框创建 | ADD_ELEMENT | 新增 TextBlockElement |
| 文本框删除 | DELETE_ELEMENT | 移除的元素 |
| 形状替换 | REPLACE_ELEMENT | 原笔画 + 新形状（需要新 action 类型） |

如 UndoableAction 结构不够用，可扩展字段（不改已有字段语义）。
Undo/Redo 后刷新画布 + 资料库缩略图（如已实现）。

## 验收标准

- [ ] 标题可编辑且持久化，资料库同步显示
- [ ] 选区移动后 Undo → 笔画回到原位
- [ ] 文本框删除后 Undo → 文本框恢复
- [ ] 形状替换后 Undo → 恢复原始手画笔画
- [ ] `check_ets_files` + `build_project` 通过 + 模拟器不崩溃

## 完成报告

`docs/migration/reports/T-036-完成.md`
