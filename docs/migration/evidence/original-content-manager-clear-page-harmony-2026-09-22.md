# Phase 550 — 原版内容管理器“Clear Page”（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/editor/PageManagerBar.ets`、
`NotePage.ets`、`NoteCanvasView.ets`、双语言字符串、专项 replay。

## 原版证据链（decompiled_1.0.3）

- `n9j.java`（内容管理器工具栏）与 `tfh.java`（每页操作表单）均暴露
  `R.string.feature_note__content_manager_clear_page` +
  `R.drawable.ui_designsystem__clear_page` 动作；`tfh` 中顺序为
  Bookmark → Clear Page（表单尾部破坏区）。
- `strings.xml`：标签为 "Clear Page"；`content_manager_*` 命名空间内
  无确认文案——清空依赖撤销栈回退，无确认对话框。
- 语义：删除该页全部元素（笔画/形状/文本/图片/数学块），保留页面本身。

## Harmony 落地

- `PageManagerBar.buildPageMenu()` 新增 Clear Page 项，位于
  Bookmark 与 Delete Page 之间（对齐 `tfh` 表单尾部顺序），沿用
  `busy || photoImportLeaseActive` fail-closed 守卫。
- `NotePage` 经 `clearPageSignal`（与 undoSignal/redoSignal 同一
  信号模式）驱动 `NoteCanvasView`。
- `NoteCanvasView.clearCurrentPageContent()`：按 `elementOrder`
  枚举当前页全部元素 ID 分桶（STROKE/SHAPE/TEXT/IMAGE/MATH；
  组成员以 STROKE 身份出现），`selectElementIds` 全选后复用
  `onSelectionMenuAction(SelectionMenuAction.DELETE)` 管线——
  撤销动作、历史元数据、持久化、图层重建与图片资源刷新全部由
  现有删除路径处理；空页直接返回。

## 差异登记

- 原版 Clear Page 位于完整内容管理器（缩略图网格 + 多选页操作）；
  Harmony 页面管理为紧凑溢出菜单，动作作用于当前页而非勾选页集合。
- 原版无确认对话框；Harmony 同样无确认，可经撤销恢复。
