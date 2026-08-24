# ADR-0355：新建笔记打开失败上下文绑定

Status: Accepted - Phase 378（2026-08-24）

## Context

`LibraryPage.createAndOpen()` 的创建成功与失败续体已校验 lifecycle、pageActive 和 ViewModel 身份；但随后导航到
新建笔记的 `router.pushUrl()` 失败时无条件弹提示。用户在路由 await 期间离开或换代后，迟到异常仍可触达旧页面。

## Decision

- 导航失败先记录 durable 错误日志，再复用同一 lifecycle/pageActive/ViewModel 门禁。
- 陈旧或销毁态直接返回，不弹“created_note_open_failed”。
- 活动页提示语义不变；`createBusy` 继续由 finally 权威清理。

## Consequences

旧 LibraryPage 不再显示迟到的打开新建笔记失败。真实设备快速导航矩阵仍属后续验收；本决策不启动模拟器、虚拟机、真机或 Hypium。
