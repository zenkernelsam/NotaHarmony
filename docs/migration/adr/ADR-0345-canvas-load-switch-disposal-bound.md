# ADR-0345：Canvas 加载与切页销毁绑定

Status: Accepted - Phase 368（2026-08-24）

## Context

NoteCanvasView 销毁设置 `lifecycleActive=false` 但不递增 pageLoadGeneration。初始加载和切页的成功续体只检查
代数/页身份，迟到成功可向已销毁组件发布元素、历史、视口并启动资源刷新；切页失败还可恢复旧页、请求回调或
弹提示。

## Decision

- 初始加载与切页入口先拒绝销毁态，避免 dispose-before-entry 继续变更 loading 状态。
- 主要成功门禁改为 `lifecycleActive + 同代 + 目标页一致`；历史恢复门禁同样绑定生命周期。
- 切页失败在同代且已销毁时直接返回，不执行回滚、失败态、toast 或 onRequestPage。
- 同代 finally 的 dataLoading 清理保留；durable 数据结果保持权威。

## Consequences

旧 Canvas 不再因加载/切页迟到结果发布 UI。真实设备快速翻页与打开/关闭矩阵仍属后续验收；本决策不启动模拟器、
虚拟机、真机或 Hypium。
