# ADR-0281: Guard Paste Cache Against Page Changes

日期：2026-08-23（Asia/Shanghai）
状态：Accepted

## Context

Phase 302 在粘贴完成后重同步剪贴板缓存，但异步插入期间用户可切换页面或笔记。完成 probe 若直接写入全局
`systemClipboardImageAvailable`，旧页面的结果会覆盖新页面的缓存；早退 probe 清 false 也存在同类污染。

## Decision

进入粘贴时捕获 `pageLoadGeneration` 与 `loadedPageId`。早退 MIME probe 失败只在页面上下文未变化时清缓存；
授权前发现切换立即返回。完成后仍执行一次无权限 MIME probe，但只有 generation 与 pageId 仍匹配才把
`probe && insertedCount > 0` 写入当前缓存。probe 不读取 PasteData、不解码 PixelMap、不请求权限；持久化结果
由既有 `insertOriginalPhotos()` 页面快照负责。