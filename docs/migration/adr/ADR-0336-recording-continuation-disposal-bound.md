# ADR-0336：录音续体销毁绑定

Status: Accepted - Phase 359（2026-08-24）

## Context

录音列表加载、捕获持久化、时间线 seek、自动连播和批量删除都包含 durable 或 player await。部分入口
只在 await 前检查 `editorDisposed`，迟到续体仍可发布 recordings、重算 timeline、清除删除预约或错误
复位连播 in-flight 标记。

## Decision

- `loadRecordings()` 的列表 await 后联合检查 disposal 与 request generation；陈旧结果不发布。
- 捕获保存和批量删除在二次 `loadRecordings()` 后复查 disposal，只有活动编辑器才重建 timeline 或清空
  pending delete IDs；durable 结果保持权威。
- 自动连播的 player load 后不向已销毁实例写状态；seek 触发的加载完成后才允许清除 seek 的 in-flight
  标记。
- 失败路径、控制器释放和既有 generation 语义不变。

## Consequences

旧实例不能跨销毁边界消费迟到录音结果或破坏新实例的状态机。真实设备快速播放、连播、删除撤销与返回
矩阵仍属后续验收；本决策不启动设备或 Hypium。
