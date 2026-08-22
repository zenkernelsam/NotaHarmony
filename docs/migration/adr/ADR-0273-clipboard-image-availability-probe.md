# ADR-0273: Clipboard Image Availability Probe

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Android 原版在渲染 Paste 菜单前用 `ClipboardManager.getPrimaryClipDescription()` 的
`hasMimeType("image/*")` 判定 `ClipboardImage`。Harmony Phase 291 只检查编辑器就绪，导致系统剪贴板没有
PixelMap 时也显示图片 Paste；点击后才失败并弹错误提示。

## Decision

新增可注入的 SystemPasteboard MIME 可用性探测。生产路径调用 SDK 自 API 14 提供的
`SystemPasteboard.getMimeTypes(): Promise<Array<string>>`，只比较 exact `pasteboard.MIMETYPE_PIXELMAP`；
不读取 PasteData、不解码 PixelMap、不提前请求 READ_PASTEBOARD。探测异常返回 false。画布页面加载和切换时
刷新状态，切换前显式清零；菜单继续要求无内部剪贴板内容，实际粘贴仍先通过 READ_PASTEBOARD gateway 再读取
数据。

## Consequences

- 菜单可见性对齐原版“先看剪贴板描述”的分流语义；
- 元数据探测与受权数据读取分层，避免只为显示菜单而触发权限；
- 探测失败 fail closed，但系统服务时序、厂商 MIME 兼容矩阵和真实权限体验仍需设备验收；
- `T-042` 不受影响，继续保留为 Goal 最后一项。
