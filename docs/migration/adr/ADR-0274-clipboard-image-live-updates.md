# ADR-0274: Clipboard Image Live Availability Updates

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Phase 295 已用 MIME 元数据决定菜单可见性，但 Canvas 只在页面加载后探测一次。编辑器保持打开时，
用户在其他应用复制新图片不会刷新状态；原版每次菜单判定都读取当前 `ClipDescription`。

## Decision

Canvas 在组件出现时订阅 SystemPasteboard 的 SDK `on('update')` 事件，消失时用同一 callback 精确
`off('update')`。事件只触发既有 MIME probe 刷新；probe 仍 fail closed，不读取数据、不解码图像、也不请求权限。
订阅/退订异常记录日志并保持状态清理；页面切换仍先置 false，避免异步旧结果跨页回写。
