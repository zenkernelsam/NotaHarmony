# ADR-0327：偏好设置保存销毁绑定

Status: Accepted - Phase 350（2026-08-24）

## Context

SettingsPage 的形状识别开关和 DefaultTemplatePage 的默认模板都采用乐观 UI 保存。两个页面此前没有
aboutToDisappear；用户在持久化 await 期间返回后，迟到失败会回滚内存设置并弹 toast，迟到成功也会弹 toast。

## Decision

- 两页销毁时设置 pageDisposed；加载成功/失败路径在发布前检查。
- 每次乐观保存捕获独立 lifecycle generation，await 成功与 catch 回滚前都校验销毁态和同代身份。
- 过期续体直接返回，不回滚 UI、不显示成功/失败提示；finally 继续复位 saveBusy。
- durable 偏好保持权威，下一次页面加载读取 EditorSettingsStore 的真实值。

## Consequences

UI 不能被已离开页面的迟到保存结果改写。真实设备快速交互、进程恢复和多实例组合验收继续独立开放。
