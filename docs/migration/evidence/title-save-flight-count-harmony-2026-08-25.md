# Phase 433 标题保存飞行计数 Harmony 证据（2026-08-25）

## 源码顺序

- `NotePage.saveTitle()` 每次入队执行 `titleSaveInFlightCount++`。
- 对应 `queued.finally()` 在该次 durable commit 成功或失败后递减一次；串行队列尾部仍由
  `titleSaveQueue.catch()` 维持可用。
- `onApplyNoteTitleHistory()` 与 `onApplyNoteMetadataHistory()` 均在
  `pageOperationBusy || titleSaveInFlightCount > 0` 时 fail closed。

## 缺口

Phase 431 的布尔标志只表达“是否存在任务”，无法区分多个排队任务的 settle 顺序。若第二次
标题保存仍在队列中等待，第一次的 finally 会提前清零布尔值，历史入口可能在共享 note 状态
尚未稳定时放行。

## 断言

- 新增专项 Replay `d02-title-save-queue-count-bound.mjs`（4/4）：
  - 计数字段存在且旧布尔字段完全移除；
  - 每次 save 恰好一次递增和一次所属 finally 递减；
  - 标题与 metadata 历史入口都要求全部任务 settle 后才开放；
  - Canvas 分流入口保持不变。

## 边界

未启动模拟器、虚拟机、真机或 Hypium；T-042 继续 Goal 最后任务。
