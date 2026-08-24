# ADR-0325：WebDAV 设置页迟到结果销毁绑定

Status: Accepted - Phase 348（2026-08-24）

## Context

WebDAV 设置页的配置读取、不安全 HTTP 风险确认、连接测试和保存事务都会产生异步续体。此前页面没有
`aboutToDisappear()` 生命周期；用户离开后，迟到读取可覆盖状态，迟到测试可发布结果，迟到保存可对旧页面弹 toast。

## Decision

- 页面销毁时设置 `pageDisposed` 并递增 `lifecycleGeneration`。
- 配置加载、风险确认、HTTP 测试和保存事务的 await 后都检查完整生命周期身份。
- 销毁后的迟到成功或失败直接返回，不再写 UI 状态、发布测试结论或显示 toast。
- `safeToast()` 额外拒绝销毁态调用。durable 配置与共享操作租约语义保持权威；租约仍在 `finally` 中释放。

## Consequences

UI 续体不能越过页面生命周期写入已消失的界面。持久化保存仍由 `WebDAVConfigStore.save()` 权威提交；
下一次进入设置页通过正常加载观察 durable 结果。真实 WebDAV 服务器矩阵和设备交互验收继续独立开放。
