# ADR-0403：NOTE_TITLE 历史与标题保存代绑定

## 状态

已接受（2026-08-25，Phase 431）。

## 背景

Phase 429 后，页面级历史命令的成功/失败续体都会释放导航租约。但 `commitTitle()` 的
durable 标题事务由独立 `titleSaveQueue` 驱动；如果 Undo NOTE_TITLE 在该队列仍在飞行时进入，
`validatePageActionState()` 可能仍读到旧标题并通过校验，随后与队列中的标题写入竞争。
`historyBusy` 只约束 Canvas 历史，不能表达 NotePage 的标题保存状态。

## 决策

1. 为 NOTE_TITLE 历史增加独立入口 `onApplyNoteTitleHistory()`，非标题页面动作继续走原入口。
2. 新增权威 `titleSaveInFlight`，从每次 save 入队置位，到该次 durable commit settle 后 finally 清零。
3. 页面操作进行中或标题保存飞行中，NOTE_TITLE 历史直接 fail closed；导航租约由 Phase 429 续体释放。
4. 不改变普通标题提交、离开编辑器等待、disposal 守卫和持久化物化语义。

## 后果

NOTE_TITLE 历史不再依赖可能过期的源状态快照去竞争标题队列；拒绝路径可立即恢复翻页。
后续若其他 note-level metadata 也出现外部队列，应复用同一“权威 in-flight + 独立历史入口”边界。
