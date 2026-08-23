# ADR-0282: Abort Paste After Permission On Page Change

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Phase 303 在授权前检查发起页面，但 `ensureOriginalClipboardReadPermission()` 是异步边界。用户在授权期间切页后，
旧粘贴流程仍会读取 PasteData、解码规范化 PixelMap，并把图像提交到已离开的旧页；完成缓存重同步虽然被页面守卫，
持久化结果已经落盘。

## Decision

权限网关成功后立即重新比较入口捕获的 `pageLoadGeneration` 与 `loadedPageId`。页面上下文变化时直接返回，
不读取数据、不规范化、不创建 pending draft，也不进入持久化事务。同页流程保持既有 busy 串行化、MIME 复查和
fail-closed 语义。
