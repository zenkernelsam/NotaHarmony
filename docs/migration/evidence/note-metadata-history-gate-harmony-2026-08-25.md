# Phase 432 NOTE_METADATA 历史 note 状态门禁 Harmony 证据（2026-08-25）

## 源码顺序

- `NoteCanvasView` 新增 `isNoteMetadataAction()`，页面历史分支按 `NOTE_TITLE`、`NOTE_METADATA`
  和其他页面动作分流。
- `NOTE_TITLE` 继续使用 Phase 431 的标题保存代入口；`NOTE_METADATA` 使用新增的
  `onApplyNoteMetadataHistory()`。
- `NotePage` 的 metadata 历史入口在 `pageOperationBusy || titleSaveInFlight` 时返回 false，
  否则进入既有 `applyPageHistory()`。

## 缺口

Phase 431 后 NOTE_METADATA 仍依赖通用入口。虽然当前没有生产 caller 创建该动作，
但持久化层和撤销栈保留恢复路径；未来 note-level metadata 队列若恢复，通用入口无法感知共享
note 状态正在变化。

## 断言

- 新增专项 Replay `d02-note-metadata-history-gate-bound.mjs`（3/3）：
  - metadata 入口先检查 page operation 与 title in-flight，fail closed 后才允许 apply；
  - Canvas 分支顺序为 title -> metadata -> generic page action；
  - 三类入口均接入同一导航租约释放续体。

## 边界

未启动模拟器、虚拟机、真机或 Hypium；T-042 继续 Goal 最后任务。
