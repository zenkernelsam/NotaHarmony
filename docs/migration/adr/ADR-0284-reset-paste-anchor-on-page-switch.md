# ADR-0284: Reset Paste Anchor On Page Switch

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

原版普通 Paste 使用本次手势/菜单请求携带的 `DocPxOffset`，不使用递增偏移。Harmony 为桥接异步 context-menu
callback 保留最近长按画布坐标，但该锚点没有随页面切换清理；用户在新页触发系统剪贴板图片 Paste 时，可能复用
旧页坐标，造成错误落点。

## Decision

新页数据成功 hydrate 时立即把 `clipboardPasteTarget` 置为 null。后续粘贴若无本次长按锚点，继续使用当前视口
中心；有新锚点时仍严格使用该坐标。锚点不参与 undo、持久化或剪贴板可用性缓存。
