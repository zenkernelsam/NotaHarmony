# ADR-0406：录音完成推进所有权计数

## 状态

已接受（2026-08-25，Phase 434）。

## 背景

`completionAdvanceInFlight` 是布尔所有权标志。自动连播的 `load()` 与用户时间线 seek 的
`load()` 都会竞争同一控制器互斥队列。若 seek 先入队并使旧自动任务先 settle，旧任务会把布尔值清零；
随后新录音再次 COMPLETED 时，入口误判没有推进在飞，自动时间线推进永久丢失。

## 决策

1. 用权威计数 `completionAdvanceCount` 表达仍在 settle 前的自动推进任务数量。
2. 每次 COMPLETED 快照触发一次自动推进就递增一次；该 promise 由自己的 `finally` 递减一次。
3. 用户 seek 继续通过控制器代际使旧 load 失效，但不改写其他任务的计数。
4. 异步函数内部不重复释放所有权；销毁、无下一曲和 load 失败都由调用方 finally 覆盖。

## 后果

并发 load 的 settle 顺序不再决定门禁状态。只要还有一个自动推进 promise 未 settle，计数保持大于零；
全部 settle 后，后续完成事件可以重新触发推进。用户 seek 仍保留最终控制权。
