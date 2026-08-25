# Harmony 证据：录音完成推进所有权计数（2026-08-25）

## 静态缺口

`NotePage.onRecordingPlaybackSnapshot()` 原先以 `completionAdvanceInFlight` 布尔值阻止重复自动推进。
该标志没有任务所有权：自动连播 `load()` 与用户 seek `load()` 共享控制器互斥队列时，后入队者可能使
先入队的自动任务先 settle。旧任务的清理会把布尔值清零，而新 load 尚未 settle；随后 COMPLETED 快照
会被误判为无推进在飞。

## 修复边界

- 自动推进入口每次递增 `completionAdvanceCount`。
- 触发的 promise 通过自身 `finally` 递减，销毁、无下一曲和失败路径都覆盖。
- 用户 seek 只发起新的控制器代际请求，不抢占或清零旧任务计数。
- 异步函数不再重复管理布尔状态，避免 settle 顺序改变门禁真相。

## 可验证性

专项 Replay 固化以下断言：

1. 旧布尔字段完全移除。
2. 完成事件入口先递增、promise finally 后递减。
3. 自动推进函数内部不重复释放计数。
4. 用户 seek 的 disposed 路径不触碰计数。

运行态验证仍受 Goal 约束限制：未启动模拟器、虚拟机、真机或 Hypium。
