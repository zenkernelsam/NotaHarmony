# ADR-0405：标题保存飞行计数

## 状态

已接受（2026-08-25，Phase 433）。

## 背景

Phase 431 用布尔 `titleSaveInFlight` 表达标题队列状态，但 `titleSaveQueue` 允许多次保存
排队。第二次入队时旧 promise 的 `finally` 可能在新任务仍在队列中时清零布尔值，使标题或
metadata 历史在共享 note 状态尚未稳定时放行。

## 决策

1. 将布尔标志替换为权威计数 `titleSaveInFlightCount`。
2. 每次 `saveTitle()` 入队递增一次；对应 durable commit settle 后由自己的 finally 递减。
3. NOTE_TITLE 与 NOTE_METADATA 历史入口统一要求 `count > 0` 时 fail closed。
4. 不改变串行队列、失败吞并、disposal 守卫和导航租约释放语义。

## 后果

飞行门禁现在覆盖“正在执行”和“仍被排队”的全部标题任务；不会因前一个 settle 提前开放历史入口。
后续若引入独立 metadata 队列，应采用同一所有权计数模式。
