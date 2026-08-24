# ADR-0354：页面重载失败上下文绑定

Status: Accepted - Phase 377（2026-08-24）

## Context

`LibraryPage.onPageShow()` 重载的成功续体已联合校验 lifecycle、ViewModel、renderer 和 notes request，但失败续体
先修改 loading/initError 并弹提示，再记录日志；快速离开或换代后的迟到异常可触达旧页面。

## Decision

- 失败续体先保留 durable 错误日志，再复用成功路径同一 `isCurrentLifecycle` + `isCurrentNotesRequest` 门禁。
- 陈旧/销毁续体不发布 loading、initError，也不弹提示。
- 活动页重载失败语义不变。

## Consequences

旧 LibraryPage 不再显示迟到的页面重载失败。真实设备快速切换矩阵仍属后续验收；本决策不启动模拟器、虚拟机、真机或 Hypium。
