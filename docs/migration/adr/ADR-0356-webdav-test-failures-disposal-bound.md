# ADR-0356：WebDAV 测试失败销毁绑定

Status: Accepted - Phase 379（2026-08-24）

## Context

WebDAV 设置页 `testConnectionOnce()` 的成功续体已校验 lifecycleGeneration，但 HTTP 明文确认失败与连接请求失败两个 catch 在记录日志后无条件写入测试结果。用户在异步等待期间离开或换代后，迟到异常仍可触达旧 UI。

## Decision

- 两个失败 catch 先保留 durable 错误日志，再复用同一 lifecycleGeneration 销毁门禁。
- 陈旧或销毁态直接返回，不发布 testSucceeded、testResult 和 hasTestResult。
- 活动页测试失败语义不变；外层 finally 继续权威清理 isTesting。

## Consequences

旧 WebDAVSettingsPage 不再显示迟到的测试失败状态。真实设备快速导航矩阵仍属后续验收；本决策不启动模拟器、虚拟机、真机或 Hypium。
