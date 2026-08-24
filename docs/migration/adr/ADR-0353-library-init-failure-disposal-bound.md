# ADR-0353：资料库初始化失败销毁绑定

Status: Accepted - Phase 376（2026-08-24）

## Context

`LibraryPage.initData()` 成功续体已联合校验 pageActive 与 lifecycle generation，但外层失败 catch 先发布加载错误、
重试提示，再记录日志；离开或重建后的迟到异常可触达旧页面。

## Decision

- 失败续体先保留 durable 错误日志，再检查 `pageActive` 和 lifecycle generation。
- 陈旧/销毁态直接返回，不修改 loading/initError，也不弹提示。
- 活动页初始化失败语义不变。

## Consequences

旧 LibraryPage 不再显示迟到的资料库初始化失败。真实设备快速退出矩阵仍属后续验收；本决策不启动模拟器、虚拟机、真机或 Hypium。
