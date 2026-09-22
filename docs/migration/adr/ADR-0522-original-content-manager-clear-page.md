# ADR-0522 — 原版内容管理器“清空页面”

状态：Accepted（Phase 550）

## 背景

原版内容管理器（`n9j`/`tfh`）暴露 per-page "Clear Page" 动作：删除
该页全部元素、保留页面、无确认、可撤销。Harmony 紧凑页面菜单仅有
前移/后移/书签/删除页面，缺少内容级清空入口。

## 决策

1. `PageManagerBar` 溢出菜单在 Bookmark 与 Delete Page 之间插入
   Clear Page（对齐 `tfh` 表单尾部顺序），沿用统一 busy 守卫。
2. `NotePage` 通过 `clearPageSignal` 信号驱动画布（与 undo/redo
   同一模式）。
3. `NoteCanvasView.clearCurrentPageContent()` 按 `elementOrder`
   分桶全部元素 ID，`selectElementIds` 全选后复用
   `onSelectionMenuAction(DELETE)`——删除、撤销、持久化与图层
   重建不引入第二实现；空页无操作。
4. 无确认对话框（原版命名空间无确认文案），撤销栈提供回退。

## 差异

- 原版作用于内容管理器中勾选的页集合；Harmony 作用于当前页
  （紧凑菜单无多选页模型，登记适配）。

## 验证

`d02-original-content-manager-clear-page.mjs` 25/25；全套 replay
通过（`d02-page-bar-shared-lease-bound.mjs` 计数锚点 10→11 随
`onClearPage` 回调登记更新）；`note@default` + `note@ohosTest`
BUILD SUCCESSFUL。
