# ADR-0277: Paste Execution Availability Recheck

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

菜单显示依赖缓存的 `systemClipboardImageAvailable`，但点击回调可能晚于剪贴板变化执行。原入口只检查编辑器
状态；若系统剪贴板已从 PixelMap 变为文本/空，仍可能请求 READ_PASTEBOARD 并读取失败。

## Decision

`startOriginalClipboardImagePaste()` 先用统一 `canUseOriginalClipboardImage()` 检查页面与缓存状态，再执行
一次当前 MIME availability probe。probe false 或异常时清缓存并静默返回，不进入权限请求和数据读取。通过后
继续既有 exact READ_PASTEBOARD gateway、PixelMap 读取和原版规范化链。
