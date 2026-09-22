# ADR-0525: 原版页删除提示

日期：2026-09-22（Phase 554）

## 背景

原版内容管理器删除页面后经 snackbar 提示 "Page deleted"；Harmony 删除页面
静默完成，用户缺少操作反馈。

## 决策

1. `deleteCurrentPageLocked` 在删除完全提交（checkpoint 写入、页面列表更新、
   下一页选中、undo 历史入栈）后弹 `page_deleted` toast。
2. `editorDisposed` 时 fail-closed——与既有生命周期守卫一致。
3. snackbar→toast 为平台适配，文案保持原义。

## 理由

- 提示落在提交之后而非删除按钮回调处，保证"真的删成功才提示"，
  与原版事件流语义一致。
- 不引入撤销按钮：Harmony 已有完整 undo 管线，toast 仅做反馈。

## 备选

- 在 PageManagerBar 菜单回调弹提示：回调先于删除提交，无法区分成功/失败，
  弃用。
