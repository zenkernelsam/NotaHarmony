# ADR-0342：录音列表失败销毁绑定

Status: Accepted - Phase 365（2026-08-24）

## Context

`loadRecordings()` 成功续体已联合检查 `editorDisposed` 与请求代数，但失败续体只比较代数。销毁时递增
代数可挡住多数迟到异常，但同一 await 内同步进入失败或代数更新与异常同轮完成时，旧 NotePage 仍可能清空
recordings、重建时间线并弹加载失败提示。

## Decision

- 失败续体使用与成功续体一致的 `editorDisposed || generation mismatch` 门禁。
- 销毁后的迟到失败不清空本地录音、不重建时间线，也不弹 toast。
- 同代 `finally` 继续权威清理 `recordingsLoading`；成功路径和请求刷新契约不变。

## Consequences

旧 NotePage 不再因录音列表迟到失败重置 UI。真实设备快速进出与数据库故障矩阵仍属后续验收；本决策不启动
模拟器、虚拟机、真机或 Hypium。
