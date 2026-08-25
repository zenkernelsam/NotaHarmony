# Phase 431 NOTE_TITLE 历史保存代 Harmony 证据（2026-08-25）

## 源码顺序

- `NotePage.saveTitle()` 每次入队时置位 `titleSaveInFlight`，`queued.finally()` 在该次
  durable commit 成功或失败后清零；`titleSaveQueue` 仍保持串行尾部可用。
- `NotePage` 新增 `onApplyNoteTitleHistory()`：`pageOperationBusy || titleSaveInFlight`
  时返回 false，否则才进入 `applyPageHistory()`。
- `NoteCanvasView.isNoteTitleAction()` 只分流 `NOTE_TITLE`；其他页面级动作继续使用
  `onApplyPageHistory()`。两条入口共用 Phase 429 的成功/失败释放导航租约续体。

## 缺口

标题 Undo/Redo 原先直接调用 `applyPageHistory()`。若 `commitTitle()` 队列仍在飞行，
源状态校验可能读取旧标题并放行，随后两个 SQLite 标题事务竞争；`historyBusy` 无法感知
NotePage 的外部队列。

## 断言

- 新增专项 Replay `d02-title-history-generation-bound.mjs`（3/3）：
  - `titleSaveInFlight` 从 save 入队到 finally 清零；
  - 标题历史入口先检查 page operation 与 title in-flight，fail closed 后才允许 apply；
  - Canvas 按 `NOTE_TITLE` 分流到独立入口。
- 相邻页面历史命令、生命周期、标题提交上下文、删除租约和结构租约 Replay 全部通过。

## 边界

未启动模拟器、虚拟机、真机或 Hypium；T-042 继续 Goal 最后任务。
